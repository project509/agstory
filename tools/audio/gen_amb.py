#!/usr/bin/env python3
"""Generate the five ambience beds -- camp, tavern, market, cave, dungeon.

WHY THIS FILE EXISTS
    Six stages mounted in silence (AUDIO-07). docs/13 §12.2 keeps the UI
    from looping ("Nothing in the UI loops, pulses, or breathes") and gives
    the world layer the ambient motion; an ambience LOOP is world-layer by
    the doc's own split, and the ruling (Q-98 (ii), BL-138) puts five
    generated beds on the Music bus, keyed by scene, behind the one door in
    `SceneStage.load()`. This file renders those five, from the same kind of
    crude physical models gen_sfx.py uses for the one-shots: filtered noise
    for fire, wind and air; formant-filtered noise voices for a crowd;
    damped inharmonic partials for a clink; stick-slip grain for a chain.
    Nothing is downloaded, sampled or licensed (docs/00 §4.4 (5), AUDIO-17).

SEAMLESS LOOPS
    Each bed is rendered N + FOLD samples long and the tail is folded into
    the head with an equal-power crossfade, so the loop point carries no
    click and no level step. Every slow modulator is a sum of sines with an
    integer number of cycles per loop, so the gusts and swells wrap exactly;
    the fold only has to hide the noise floor's seam. `--check` measures the
    wrap: the RMS of the window straddling the loop point against the bed's
    own RMS, and the sample step across the seam against the bed's own step
    distribution (a click is an outlier step).

LEVELS (BL-138)
    44.1 kHz mono 16-bit, RMS -30 dBFS, peak <= -20 dBFS. A Gaussian bed's
    crest factor is ~12 dB, so an RMS of -30 alone puts peaks near -18; a
    soft knee from -24 dB folds everything above it under -20 without
    changing what the bed sounds like. The Music bus setting is the level
    the player hears; these are the bed's own headroom.

DETERMINISM
    Every layer seeds its own Generator from sha256("<bed>:<layer>"), so a
    re-render is byte-identical and the tree does not churn. `--check` is the
    gate (tools/build_art.sh --check, verify stage 2b): AGREE / DIFFERS /
    MISSING per bed, ORPHAN for a stray .wav, LOOP per bed, DISTINCT across
    the set (the dungeon is a recombination of the cave's layers plus one
    event, and must not be anyone's bytes).

USAGE
    python tools/audio/gen_amb.py               # write game/assets/audio/amb/
    python tools/audio/gen_amb.py --list        # print the manifest, write nothing
    python tools/audio/gen_amb.py --out DIR     # write somewhere else
    python tools/audio/gen_amb.py --check       # re-render to a temp dir, compare

    Godot needs `--import` after a real change (tools/audio/README.md); the
    `.import` beside each bed says `edit/loop_mode=2` (forward), which is what
    makes the AudioStreamWAV loop at all.
"""

from __future__ import annotations

import argparse
import filecmp
import hashlib
import os
import shutil
import sys
import tempfile
import wave

import numpy as np

# The DSP primitives are gen_sfx.py's, so the beds and the one-shots share one
# definition of a band, a grain and a struck body. `sys.path[0]` is this
# directory when the script is run by path, and the import is explicit about
# that rather than relying on a package.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_sfx import SR, ar, band, hump, noise, stick_slip, struck  # noqa: E402

FOLD_MS = 600.0        # the tail folded into the head, equal-power
RMS_DB = -30.0         # BL-138
PEAK_DB = -20.0        # BL-138
KNEE_DB = -24.0        # where the soft knee starts
CREST_SIGMA = 2.5      # a continuous layer is rounded at this many sigma
TREE = "game/assets/audio/amb"


# ------------------------------------------------------------------ utilities


def seed_for(bed: str, layer: str) -> np.random.Generator:
    digest = hashlib.sha256(("%s:%s" % (bed, layer)).encode()).digest()[:8]
    return np.random.default_rng(int.from_bytes(digest, "big"))


def lfo(rng: np.random.Generator, m: int, period: int, cycles_lo: int,
        cycles_hi: int, k: int = 3) -> np.ndarray:
    """A slow 0..1 modulator that is exactly periodic in `period` samples.

    A sum of k sines, each an integer number of cycles per loop with a random
    phase. Because every component wraps at the loop point the modulation
    does too, so a gust that is rising at 25.0 s is rising at 0.0 s.
    """
    t = np.arange(m) / float(period)
    out = np.zeros(m)
    for _ in range(k):
        c = int(rng.integers(cycles_lo, cycles_hi + 1))
        out += np.sin(2.0 * np.pi * (c * t + rng.uniform()))
    return 0.5 + 0.5 * out / k


def event_times(rng: np.random.Generator, span_s: float, lo_s: float,
                hi_s: float) -> list[float]:
    """Event start times in [0, span): the first inside the first gap, then
    every lo..hi seconds. The spacing rule is the doc's number for each event
    ("every 6-14 s", "every 20-40 s"); the loop length decides how many land."""
    out: list[float] = []
    t = float(rng.uniform(0.0, hi_s))
    while t < span_s:
        out.append(t)
        t += float(rng.uniform(lo_s, hi_s))
    return out


def place(buf: np.ndarray, at_s: float, grain: np.ndarray, gain: float = 1.0) -> None:
    """Add `grain` into `buf` starting at `at_s`, clipped to the buffer."""
    i = int(at_s * SR)
    if i >= buf.size:
        return
    k = min(grain.size, buf.size - i)
    buf[i:i + k] += gain * grain[:k]


def n_of(seconds: float) -> int:
    return int(round(SR * seconds))


# --------------------------------------------------------------------- layers
#
# Every layer takes the rng seeded for it, the render length `m` (loop + fold)
# and the loop length `n` (the modulators' period) and returns a float array
# of length m at its own natural level; the bed's `mix` table sets the gains.


def fire(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """A hearth: the low roar of the embers, a steady crackle, a rare pop.

    Crackle is sparse bursts of 1-4 kHz noise with a sub-15 ms decay --
    each one is a fibre snapping -- at ~12 a second, log-uniform in size.
    Pops are louder, rarer (one every ~1.6 s) and carry a 120-700 Hz body.
    """
    roar = band(noise(rng, m), 60.0, 400.0) * (0.55 + 0.45 * lfo(rng, m, n, 2, 9))
    crackle_src = band(noise(rng, m), 1000.0, 4000.0)
    env = np.zeros(m)
    for _ in range(int(12 * m / SR)):
        at = int(rng.uniform(0, m))
        tau = float(rng.uniform(4.0, 14.0))
        size = 10.0 ** rng.uniform(-1.2, 0.0)
        k = min(n_of(0.06), m - at)
        env[at:at + k] += size * ar(k, 0.3, tau)
    crackle = crackle_src * env
    pop_src = band(noise(rng, m), 120.0, 700.0)
    pop_env = np.zeros(m)
    for _ in range(int(0.6 * m / SR)):
        at = int(rng.uniform(0, m))
        k = min(n_of(0.09), m - at)
        pop_env[at:at + k] += ar(k, 0.5, 18.0)
    pops = pop_src * pop_env
    return 0.45 * roar + 1.0 * crackle + 0.8 * pops


def wind(rng: np.random.Generator, m: int, n: int, lo: float = 100.0,
         hi: float = 600.0) -> np.ndarray:
    """Night wind: 100-600 Hz noise under a slow gust envelope (squared, so
    the lulls are real lulls)."""
    gust = lfo(rng, m, n, 1, 5) ** 2
    return band(noise(rng, m), lo, hi) * (0.25 + 0.75 * gust)


def air(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """A cave's low air: a 40-120 Hz hollow rumble swelling over the loop,
    with a faint 150-500 Hz breath above it."""
    rumble = band(noise(rng, m), 40.0, 120.0) * (0.6 + 0.4 * lfo(rng, m, n, 1, 4))
    breath = band(noise(rng, m), 150.0, 500.0) * (0.3 + 0.7 * lfo(rng, m, n, 2, 7) ** 2)
    return rumble + 0.22 * breath


def murmur(rng: np.random.Generator, m: int, n: int, voices: int = 5,
           f_lo: float = 200.0, f_hi: float = 800.0,
           syllable_hz: tuple[float, float] = (3.0, 5.0)) -> np.ndarray:
    """A crowd: `voices` detuned formant-filtered noise voices, each gated at
    a syllable rate and swelling on its own slow walk. Nobody says a word,
    which is the point -- it reads as talk from the next table."""
    out = np.zeros(m)
    for v in range(voices):
        f = f_lo * (f_hi / f_lo) ** ((v + rng.uniform(0.2, 0.8)) / voices)
        src = noise(rng, m)
        voice = band(src, f / 1.4, f * 1.4) + 0.4 * band(src, f * 1.9, f * 2.6)
        syll = stick_slip(rng, m, float(rng.uniform(*syllable_hz)))
        syll = np.abs(syll) / (np.max(np.abs(syll)) + 1e-9)
        # The grain is the rhythm, not the timbre: smooth it to a gate.
        kernel = np.ones(n_of(0.03)) / n_of(0.03)
        gate = np.convolve(syll, kernel, mode="same")
        swell = 0.3 + 0.7 * lfo(rng, m, n, 2, 8) ** 1.5
        out += voice * gate * swell
    return out / voices


def chatter(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """The market's crowd: the tavern's murmur brighter (300-1400 Hz), busier
    (seven voices) and faster (4-7 syllables a second)."""
    return murmur(rng, m, n, 7, 300.0, 1400.0, (4.0, 7.0))


def clink(rng: np.random.Generator, m: int, n: int, lo_s: float = 6.0,
          hi_s: float = 14.0) -> np.ndarray:
    """Pewter and glass meeting somewhere in the room: a damped inharmonic
    bank every 6-14 s, each strike its own pitch and weight."""
    out = np.zeros(m)
    for t in event_times(rng, n / SR, lo_s, hi_s):
        f = float(rng.uniform(2100.0, 3400.0))
        k = n_of(0.35)
        body = struck([f, f * 1.48, f * 2.11, f * 2.79], [120.0, 70.0, 45.0, 30.0],
                      [1.0, 0.5, 0.28, 0.14], k)
        tick = band(noise(rng, k), 4000.0, 9000.0) * ar(k, 0.1, 2.0)
        place(out, t, body + 0.3 * tick, float(rng.uniform(0.5, 1.0)))
    return out


def cart(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """A cart passing: a 70-260 Hz wooden rumble under a 6 Hz wheel clatter,
    humped over 5-7 s, every 12-20 s."""
    out = np.zeros(m)
    for t in event_times(rng, n / SR, 12.0, 20.0):
        dur = float(rng.uniform(5.0, 7.0))
        k = n_of(dur)
        rumble = band(noise(rng, k), 70.0, 260.0)
        clatter = band(stick_slip(rng, k, 6.0), 300.0, 1800.0)
        pass_env = hump(k, 0.0, dur * 1000.0, power=1.6)
        place(out, t, (rumble + 0.35 * clatter) * pass_env)
    return out


def gull(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """One gull, some way off: two to four falling cries per cluster, a
    cluster every 8-16 s. Each cry is noise through a band gliding
    2800 -> 1700 Hz over ~220 ms."""
    out = np.zeros(m)
    for t in event_times(rng, n / SR, 8.0, 16.0):
        cries = int(rng.integers(2, 5))
        at = t
        for _ in range(cries):
            dur = float(rng.uniform(0.18, 0.26))
            k = n_of(dur)
            f0 = float(rng.uniform(2600.0, 3000.0))
            f1 = f0 * 0.6
            steps = 5
            src = band(noise(rng, k), 800.0, 6000.0)
            cry = np.zeros(k)
            for i in range(steps):
                centre = f0 * (f1 / f0) ** (i / (steps - 1.0))
                w = np.clip(1.0 - abs(np.linspace(0.0, steps - 1.0, k) - i), 0.0, 1.0)
                cry += band(src, centre / 1.25, centre * 1.25) * w
            cry *= hump(k, 0.0, dur * 1000.0, power=1.2)
            place(out, at, cry, float(rng.uniform(0.6, 1.0)))
            at += dur + float(rng.uniform(0.15, 0.45))
    return out


def drip(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """Water on stone: a pitched resonant tick at 1.2-2.5 kHz with a 40 ms
    decay every 2-7 s."""
    out = np.zeros(m)
    for t in event_times(rng, n / SR, 2.0, 7.0):
        f = float(rng.uniform(1200.0, 2500.0))
        k = n_of(0.16)
        tone = struck([f, f * 2.3], [40.0, 18.0], [1.0, 0.3], k, 0.4)
        splash = band(noise(rng, k), 2500.0, 7000.0) * ar(k, 0.2, 6.0)
        place(out, t, tone + 0.35 * splash, float(rng.uniform(0.5, 1.0)))
    return out


def creak(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """A chain taking weight: stick-slip at 2-4 Hz over 1.2 s, every 9-17 s.
    The slow catches gate a metallic 160-1300 Hz grain; a ringing partial at
    a random 300-500 Hz rides under it so the links sound like iron."""
    out = np.zeros(m)
    for t in event_times(rng, n / SR, 9.0, 17.0):
        k = n_of(1.2)
        catches = stick_slip(rng, k, float(rng.uniform(2.0, 4.0)))
        catches = np.abs(catches) / (np.max(np.abs(catches)) + 1e-9)
        kernel = np.ones(n_of(0.012)) / n_of(0.012)
        gate = np.convolve(catches, kernel, mode="same")
        grain = band(stick_slip(rng, k, 70.0), 160.0, 1300.0)
        f = float(rng.uniform(300.0, 500.0))
        ring = np.sin(2.0 * np.pi * f * np.arange(k) / SR) * gate
        body = (grain * gate + 0.25 * ring) * hump(k, 0.0, 1200.0, power=1.3)
        place(out, t, body, float(rng.uniform(0.6, 1.0)))
    return out


def stonefall(rng: np.random.Generator, m: int, n: int) -> np.ndarray:
    """A stone letting go somewhere down the passage, once a loop: an 80 Hz
    thump and a gravel scatter 40-90 ms behind it, with two or three smaller
    stones after."""
    out = np.zeros(m)
    t = float(rng.uniform(2.0, n / SR - 2.0))
    k = n_of(0.9)
    thump = struck([80.0, 130.0], [140.0, 80.0], [1.0, 0.4], k, 1.5)
    thump += 0.5 * band(noise(rng, k), 0.0, 200.0) * ar(k, 1.5, 120.0)
    gravel = band(stick_slip(rng, k, 400.0), 500.0, 3000.0)
    gravel *= ar(k, 2.0, 180.0, float(rng.uniform(40.0, 90.0)))
    tail = np.zeros(k)
    for _ in range(int(rng.integers(2, 4))):
        at = int(rng.uniform(0.25, 0.7) * k)
        j = min(n_of(0.12), k - at)
        tail[at:at + j] += band(noise(rng, j), 300.0, 2500.0) * ar(j, 1.0, 40.0) * 0.5
    place(out, t, thump + 0.6 * gravel + tail)
    return out


# ----------------------------------------------------------------------- BEDS
#
# One dict, per the same rule as gen_sfx.PARAMS: a human re-tunes here and
# nowhere else. `seconds` is the loop length; `mix` is (layer name, function,
# mode, gain) in the order the layers are summed. Each layer is normalised
# before its gain: a continuous layer ("rms") to unit RMS, so its gain is its
# share of the bed; an event layer ("peak") to unit peak, so its gain is how
# far its loudest moment stands above the bed's RMS (3.0 = +9.5 dB, a little
# over the crest of the rounded noise it sits in -- audible, never a jump). The dungeon is the
# cave's air plus the chain and the stone and NO drip (BL-138), so a player
# walking from an A-slot to an E-slot hears the same rock and a different room.

BEDS = {
    # The guild's own fire, and the night around it. The main menu's aerial
    # plays this bed by design (BL-138): the aerial is the camp from above.
    "amb_camp": {
        "seconds": 26.0,
        "mix": [("hearth", fire, "rms", 1.0), ("wind", wind, "rms", 0.6)],
    },
    # Talk from the next table, a clink, and the same hearth further off.
    "amb_tavern": {
        "seconds": 24.0,
        "mix": [("murmur", murmur, "rms", 1.0), ("clink", clink, "peak", 3.2),
                ("hearth", fire, "rms", 0.4)],
    },
    # Brighter and busier chatter, a cart, a gull.
    "amb_market": {
        "seconds": 28.0,
        "mix": [("chatter", chatter, "rms", 1.0), ("cart", cart, "peak", 2.6),
                ("gull", gull, "peak", 2.6)],
    },
    # The adventures' cave: the low air and the drip.
    "amb_cave": {
        "seconds": 22.0,
        "mix": [("air", air, "rms", 1.0), ("drip", drip, "peak", 3.2)],
    },
    # Raid 1's dungeon (Q-96): the cave's air, a chain, a stone. No drip.
    "amb_dungeon": {
        "seconds": 25.0,
        "mix": [("air", air, "rms", 1.0), ("creak", creak, "peak", 3.0),
                ("stonefall", stonefall, "peak", 3.5)],
    },
}


# ---------------------------------------------------------------- render, once


def _fold(y: np.ndarray, n: int, f: int) -> np.ndarray:
    """Equal-power fold of the last `f` samples into the first `f`."""
    out = y[:n].copy()
    t = np.linspace(0.0, 1.0, f, endpoint=False)
    fade_in = np.sin(0.5 * np.pi * t)
    fade_out = np.cos(0.5 * np.pi * t)
    out[:f] = y[:f] * fade_in + y[n:n + f] * fade_out
    return out


def _finish(x: np.ndarray) -> np.ndarray:
    """DC-remove, set the RMS to RMS_DB, fold every peak above KNEE_DB under
    PEAK_DB with a tanh knee. Deterministic, and the knee leaves the body of
    the bed (everything under -24 dB) untouched."""
    x = x - float(np.mean(x))
    rms = float(np.sqrt(np.mean(x * x)))
    if rms > 0.0:
        x = x * (10.0 ** (RMS_DB / 20.0)) / rms
    knee = 10.0 ** (KNEE_DB / 20.0)
    lim = 10.0 ** (PEAK_DB / 20.0)
    a = np.abs(x)
    over = a > knee
    a = np.where(over, knee + (lim - knee) * np.tanh((a - knee) / (lim - knee)), a)
    return np.sign(x) * a


def render(bed: str) -> np.ndarray:
    spec = BEDS[bed]
    n = n_of(spec["seconds"])
    f = n_of(FOLD_MS / 1000.0)
    m = n + f
    y = np.zeros(m)
    for layer, fn, mode, gain in spec["mix"]:
        x = fn(seed_for(bed, layer), m, n)
        if mode == "rms":
            # A Gaussian layer's crest is ~12 dB and BL-138 leaves 10 between
            # the RMS and the peak. Rounding the layer's rare excursions at
            # 2.5 sigma brings its crest to ~8 dB, so the bed sits under the
            # knee on its own and the events are what reach it. Rounded noise
            # is still noise; it is not audible as distortion.
            sigma = float(np.sqrt(np.mean(x * x)))
            x = np.tanh(x / (CREST_SIGMA * sigma)) * (CREST_SIGMA * sigma)
            ref = float(np.sqrt(np.mean(x * x)))
        else:
            ref = float(np.max(np.abs(x)))
        y += gain * x / max(ref, 1e-9)
    return _finish(_fold(y, n, f))


def _write_wav(path: str, x: np.ndarray) -> int:
    pcm = np.clip(np.round(x * 32767.0), -32768.0, 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return os.path.getsize(path)


def _read_wav(path: str) -> np.ndarray:
    with wave.open(path, "rb") as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2 and w.getframerate() == SR
        raw = w.readframes(w.getnframes())
    return np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0


def filename(bed: str) -> str:
    return "%s.wav" % bed


def manifest() -> list[str]:
    return [filename(b) for b in BEDS]


def stats(x: np.ndarray) -> tuple[float, float]:
    rms = float(np.sqrt(np.mean(x * x)))
    peak = float(np.max(np.abs(x)))
    to_db = lambda v: 20.0 * np.log10(max(v, 1e-9))
    return to_db(rms), to_db(peak)


def loop_check(x: np.ndarray) -> tuple[bool, str]:
    """The wrap-around check: the 125 ms on each side of the loop point sit
    within 3 dB of each other (no level step at the seam -- a lull on both
    sides is continuous, a lull meeting a swell is not), and the sample step
    across the seam is no outlier against the bed's own sample-to-sample
    steps (a click would be)."""
    w = n_of(0.125)
    rms_tail, _ = stats(x[-w:])
    rms_head, _ = stats(x[:w])
    steps = np.abs(np.diff(x))
    typical = float(np.quantile(steps, 0.9999))
    seam = float(abs(x[0] - x[-1]))
    ok = abs(rms_tail - rms_head) <= 3.0 and seam <= 1.5 * typical
    detail = "tail %.1f / head %.1f dBFS; seam step %.4f vs %.4f" % (
        rms_tail, rms_head, seam, typical)
    return ok, detail


def render_all(out_dir: str, quiet: bool = False) -> int:
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for bed in BEDS:
        x = render(bed)
        name = filename(bed)
        size = _write_wav(os.path.join(out_dir, name), x)
        total += size
        if not quiet:
            rms, peak = stats(x)
            print("%-12s %-16s %5.1f s  rms %6.1f  peak %6.1f dBFS  %7.1f kB"
                  % (bed, name, BEDS[bed]["seconds"], rms, peak, size / 1024.0))
    return total


def check(tree: str) -> int:
    """Re-render into a temp dir and compare with `tree`: AGREE / DIFFERS /
    MISSING per bed, ORPHAN for a stray .wav, LOOP per bed, DISTINCT over the
    set. Exit 1 on any miss."""
    tmp = tempfile.mkdtemp(prefix="gen_amb_check_")
    rc = 0
    agree = 0
    try:
        render_all(tmp, quiet=True)
        named = set()
        hashes: dict[str, str] = {}
        for bed in BEDS:
            name = filename(bed)
            named.add(name)
            want = os.path.join(tmp, name)
            have = os.path.join(tree, name)
            if not os.path.exists(have):
                print("  MISSING  %s/%s (generated, not in the tree)" % (tree, name))
                rc = 1
            elif filecmp.cmp(want, have, shallow=False):
                print("  AGREE    %s/%s" % (tree, name))
                agree += 1
            else:
                print("  DIFFERS  %s/%s" % (tree, name))
                rc = 1
            x = _read_wav(want)
            rms, peak = stats(x)
            ok, detail = loop_check(x)
            level_ok = abs(rms - RMS_DB) <= 1.5 and peak <= PEAK_DB + 0.05
            print("  %s %-12s %s; rms %.1f peak %.1f" % (
                "LOOP OK " if ok and level_ok else "LOOP BAD", bed, detail, rms, peak))
            if not (ok and level_ok):
                rc = 1
            with open(want, "rb") as fh:
                hashes[bed] = hashlib.sha256(fh.read()).hexdigest()
        if os.path.isdir(tree):
            for name in sorted(os.listdir(tree)):
                if name.endswith(".wav") and name not in named:
                    print("  ORPHAN   %s/%s (in the tree, not in the manifest)" % (tree, name))
                    rc = 1
        else:
            print("  MISSING  %s (no such directory)" % tree)
            rc = 1
        distinct = len(set(hashes.values()))
        print("  %s %d beds, %d distinct renders" % (
            "DISTINCT" if distinct == len(hashes) else "DUPLICATE", len(hashes), distinct))
        if distinct != len(hashes):
            rc = 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("GEN_AMB %s  (%d agree of %d)" % ("CHECK OK" if rc == 0 else "CHECK FAILED",
                                            agree, len(BEDS)))
    return rc


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default=TREE, help="output directory (default: %s)" % TREE)
    ap.add_argument("--list", action="store_true", help="print the manifest and exit")
    ap.add_argument("--check", action="store_true",
                    help="re-render into a temp dir and compare with --out; "
                         "exit 1 on any DIFFERS / MISSING / ORPHAN / LOOP BAD / DUPLICATE")
    args = ap.parse_args(argv)

    if args.list:
        for bed in BEDS:
            layers = ", ".join(name for name, _fn, _mode, _g in BEDS[bed]["mix"])
            print("%-12s %-16s %5.1f s  %s" % (bed, filename(bed), BEDS[bed]["seconds"], layers))
        return 0
    if args.check:
        return check(args.out)
    total = render_all(args.out)
    print("-- %d beds, %.1f kB total" % (len(BEDS), total / 1024.0))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
