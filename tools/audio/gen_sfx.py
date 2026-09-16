#!/usr/bin/env python3
"""Generate the UI one-shots docs/13 §12.4 names, from physical models.

WHY THIS FILE EXISTS AT ALL
    docs/13 §12.4: "All UI sound is *material*: paper, chalk, brass, wax, coin.
    No synthesized blips."  The project ships no third-party assets and
    generates its art from script (tools/art/*.py, tools/aseprite/*.lua), so
    audio follows the same rule.  Every sound below is therefore built from a
    crude physical model of the object that makes it -- filtered noise for
    fibre and grit, exponentially damped inharmonic partials for struck metal,
    a low-passed thump for mass hitting a desk -- and NOT from an oscillator
    playing a note.  A square wave with a decay envelope is a blip; a
    band-limited stick-slip noise burst is chalk.  That distinction is the
    whole specification.

    The model and its parameters for each hook are written down in
    tools/audio/README.md so a human can re-tune without re-deriving, and so a
    later re-render is reproducible.  PARAMS below is the single source of
    those numbers.

DEPENDENCIES
    numpy (already used by tools/art -- see tools/art/refdiff.py) and the
    stdlib `wave` module.  Nothing else, and nothing downloaded.

DETERMINISM
    Every variant seeds its own Generator from a hash of "<hook>:<index>", so
    re-running this script produces byte-identical .wav files.  These files are
    committed, and a generator that churned the repo on every run would make
    `git status` useless.

USAGE
    python tools/audio/gen_sfx.py               # write game/assets/audio/sfx/
    python tools/audio/gen_sfx.py --list        # print the manifest, write nothing
    python tools/audio/gen_sfx.py --out DIR     # write somewhere else
    python tools/audio/gen_sfx.py --check       # re-render into a temp dir and
                                                # byte-compare with the tree:
                                                # AGREE / DIFFERS / MISSING per
                                                # manifest file, ORPHAN for a .wav
                                                # the manifest does not name;
                                                # exit 1 on any miss

    `--check` is what makes the samples GATED rather than merely deterministic:
    tools/build_art.sh --check runs it beside the art generators, and
    tools/verify.sh stage 2b runs that -- so a hand-edited or stale sample, or
    a PARAMS change nobody re-rendered, fails the gate instead of shipping.

    `ui.silence` is deliberately absent from the output.  §12.4 defines it as
    "Ducks all buses to -60dB for 400ms" -- it is a mixer move, not a sample,
    and it is implemented as Audio.duck(-60.0, 0.4) in game/core/Audio.gd.
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

SR = 44100  # 44.1 kHz, per M6-AUD-03's acceptance note


# --------------------------------------------------------------------- filters
#
# All filtering is done in the frequency domain with a raised-cosine skirt.
# A real IIR filter would need scipy; an FFT mask needs only numpy, and for
# one-shots 40-450 ms long the lack of a phase response is inaudible.  The
# skirt matters: a brick-wall mask rings, and ringing is exactly the
# "synthesized" artefact §12.4 forbids.


def _skirt(freqs: np.ndarray, lo: float, hi: float, width: float) -> np.ndarray:
    """A band mask that is 1 inside [lo, hi] and rolls off over `width` octaves."""
    gain = np.ones_like(freqs)
    if lo > 0.0:
        below = freqs < lo
        # Ratio in octaves under the corner, clamped so DC does not go negative.
        oct_under = np.log2(np.maximum(freqs, 1.0) / lo)
        gain = np.where(below, np.clip(1.0 + oct_under / width, 0.0, 1.0), gain)
    if hi > 0.0:
        above = freqs > hi
        oct_over = np.log2(np.maximum(freqs, 1.0) / hi)
        gain = np.where(above, np.clip(1.0 - oct_over / width, 0.0, 1.0), gain)
    return gain


def band(x: np.ndarray, lo: float, hi: float, width: float = 1.2) -> np.ndarray:
    """Band-limit `x` to [lo, hi] Hz. lo=0 is a low-pass, hi=0 a high-pass."""
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(x.size, 1.0 / SR)
    return np.fft.irfft(spec * _skirt(freqs, lo, hi, width), n=x.size)


# ------------------------------------------------------------------- envelopes


def ar(n: int, attack_ms: float, tau_ms: float, delay_ms: float = 0.0) -> np.ndarray:
    """Attack-then-exponential-decay. The shape every impulsive sound has."""
    t = np.arange(n) / SR - delay_ms / 1000.0
    a = max(attack_ms, 0.05) / 1000.0
    env = np.where(t < 0.0, 0.0, np.where(t < a, t / a, np.exp(-(t - a) / (tau_ms / 1000.0))))
    return env


def hump(n: int, start_ms: float, end_ms: float, power: float = 2.0) -> np.ndarray:
    """A smooth rise-and-fall between two times. Used for sustained gestures
    (a page being dragged, a book being compressed) where nothing is struck."""
    t = np.arange(n) / SR * 1000.0
    u = np.clip((t - start_ms) / max(end_ms - start_ms, 1e-6), 0.0, 1.0)
    return np.power(np.sin(np.pi * u), power)


# ---------------------------------------------------------------------- models


def noise(rng: np.random.Generator, n: int) -> np.ndarray:
    return rng.standard_normal(n)


def stick_slip(rng: np.random.Generator, n: int, rate_hz: float) -> np.ndarray:
    """The grain that makes chalk chalk and not hiss.

    Chalk on slate does not slide, it catches and releases hundreds of times a
    second. Model: white noise gated by a random-walk gain resampled at
    `rate_hz`, so the burst has visible grit rather than a flat spectrum
    envelope. Same trick gives paper its fibre rustle at a lower rate.
    """
    steps = max(int(n * rate_hz / SR), 2)
    walk = rng.uniform(0.25, 1.0, steps)
    grain = np.interp(np.linspace(0.0, steps - 1.0, n), np.arange(steps), walk)
    return noise(rng, n) * grain


def struck(freqs, taus_ms, amps, n: int, attack_ms: float = 0.3) -> np.ndarray:
    """A bank of exponentially damped sinusoids: a struck rigid body.

    Coins, wax seals and brass bars ring at INHARMONIC ratios -- a disc's modes
    are Bessel zeros, not integer multiples -- which is precisely why this
    reads as metal and a harmonic stack reads as a synth tone. The ratios per
    hook live in PARAMS.
    """
    out = np.zeros(n)
    for f, tau, a in zip(freqs, taus_ms, amps):
        t = np.arange(n) / SR
        out += a * np.sin(2.0 * np.pi * f * t) * ar(n, attack_ms, tau)
    return out


def glide_band(rng: np.random.Generator, n: int, f0: float, f1: float,
               q_oct: float) -> np.ndarray:
    """Noise through a band whose centre travels f0 -> f1 over the buffer.

    Implemented as a crossfade across four static bands rather than a real
    time-varying filter: a page turn's spectrum moves slowly enough that four
    steps are indistinguishable from a sweep, and it keeps the whole file
    inside numpy.
    """
    steps = 4
    src = stick_slip(rng, n, 320.0)
    out = np.zeros(n)
    for i in range(steps):
        centre = f0 * (f1 / f0) ** (i / (steps - 1.0))
        lo = centre / (2.0 ** (q_oct / 2.0))
        hi = centre * (2.0 ** (q_oct / 2.0))
        w = np.clip(1.0 - abs(np.linspace(0.0, steps - 1.0, n) - i), 0.0, 1.0)
        out += band(src, lo, hi) * w
    return out


# ----------------------------------------------------------------------- PARAMS
#
# One dict, per M6-AUD-03's mitigation: "keep the parameters in one dict so a
# human can re-tune without re-deriving".  `peak` is the post-normalisation
# peak in dBFS -- these are UI sounds under a mix, so every one of them is
# quiet.  `ms` is the total file length; docs/13 §12.2 allows only the page
# turn and the ledger close to exceed 140 ms ("Only the last two are
# indulgent, and both are once-per-cycle commitments").
#
# `variants` is round-robin depth.  docs/13 §12.4 mandates three ONLY for
# ui.stamp; the others are chosen for fatigue on the hooks that fire most, and
# a single take where the hook fires once per cycle.

PARAMS = {
    # Tab / screen change. Two sheets of paper settling, 35 ms apart.
    "ui.tab": {
        "model": "paper", "ms": 95, "peak": -20.0, "variants": 1,
        "band": (900.0, 5200.0), "grain_hz": 240.0,
        "attack_ms": 3.5, "tau_ms": 22.0, "second_ms": 35.0, "second_gain": 0.45,
    },
    # Row select, on the brass bar wipe. A bar tapped, not a beep.
    "ui.row_select": {
        "model": "brass", "ms": 70, "peak": -23.0, "variants": 2,
        "base_hz": 1180.0, "ratios": (1.0, 2.37, 3.91), "taus_ms": (16.0, 9.0, 5.0),
        "amps": (1.0, 0.42, 0.18), "air": (3200.0, 8500.0), "air_gain": 0.30,
        "air_tau_ms": 6.0, "detune": 1.06,
    },
    # ChalkSlot fill / clear. Stick-slip is the whole sound.
    "ui.chalk": {
        "model": "chalk", "ms": 78, "peak": -22.0, "variants": 3,
        "band": (1800.0, 7000.0), "grain_hz": 620.0,
        "attack_ms": 2.0, "tau_ms": 26.0,
    },
    # The comp check turning invalid: the same stroke lower and duller, and it
    # does not stop cleanly. §12.4 fires it 60 ms after the slot redraws, so the
    # lateness is the caller's, not the sample's.
    "ui.chalk_bad": {
        "model": "chalk", "ms": 120, "peak": -21.0, "variants": 1,
        "band": (700.0, 3400.0), "grain_hz": 320.0,
        "attack_ms": 3.0, "tau_ms": 48.0,
    },
    # THE SIGNATURE SOUND. §12.4: "short, dry, and never fatiguing: <= 140ms,
    # three round-robin variants, +/-2 semitone random pitch". Three layers:
    # a 4 ms contact tick that starts on sample 0 (so the sound can never be
    # late), the wooden body of the stamp, and the platen hitting the desk.
    "ui.stamp": {
        "model": "stamp", "ms": 125, "peak": -14.0, "variants": 3,
        "tick": (3000.0, 6500.0), "tick_tau_ms": 3.0, "tick_gain": 0.55,
        "body": (380.0, 1700.0), "body_tau_ms": 13.0, "body_gain": 0.85,
        "thump_hz": 260.0, "thump_tau_ms": 34.0, "thump_gain": 1.0,
    },
    # Any WaxButton commit: soft mass, then a short brass ring off the press.
    #
    # 138 ms, not the 155 this file shipped with.  §12.4 gives an explicit
    # ceiling to exactly one hook -- the stamp's "<= 140ms" -- and no length at
    # all to the other nine.  Taking that number as the ceiling for every
    # non-indulgent one-shot is a HOUSE CHOICE (the doc does not say it), but it
    # is the doc's own number, and the seal was the only sample above it: a test
    # that cited 140 ms while letting one sample through at 155 was worth less
    # than no test.  The 2 ms of clearance is so the test never compares a
    # float32 sample length against its own bound (6,174 frames / 44,100 is
    # 0.14 either side of the last bit), not a length allowance.  The ring's
    # slowest partial has tau 60 ms, so by 138 ms it is 20 dB down and
    # _finish()'s 6 ms out-fade covers the rest.
    "ui.seal": {
        "model": "seal", "ms": 138, "peak": -18.0, "variants": 1,
        "thump_hz": 210.0, "thump_tau_ms": 52.0, "thump_gain": 1.0,
        "ring_hz": 860.0, "ratios": (1.0, 2.71, 4.13), "taus_ms": (60.0, 30.0, 14.0),
        "amps": (0.36, 0.16, 0.07), "wax": (150.0, 1100.0), "wax_gain": 0.30,
        "wax_tau_ms": 30.0,
    },
    # Gold changes. A small struck disc, inharmonic, with a bright contact tick.
    "ui.coin": {
        "model": "coin", "ms": 135, "peak": -21.0, "variants": 2,
        "base_hz": 2420.0, "ratios": (1.0, 1.59, 2.14, 2.65, 3.16),
        "taus_ms": (88.0, 62.0, 40.0, 26.0, 16.0),
        "amps": (1.0, 0.55, 0.34, 0.20, 0.11),
        "tick": (5000.0, 11000.0), "tick_tau_ms": 2.5, "tick_gain": 0.30,
        "detune": 1.093,
    },
    # Departure. One of §12.2's two indulgent moments, so it may run long: the
    # grab, the sweep of the sheet, and the flap as it lands.
    "ui.page_turn": {
        "model": "page", "ms": 380, "peak": -20.0, "variants": 1,
        "f0": 1100.0, "f1": 3300.0, "q_oct": 1.6,
        "grab_ms": (0.0, 70.0), "sweep_ms": (30.0, 300.0),
        "flap_at_ms": 285.0, "flap_hz": 420.0, "flap_tau_ms": 45.0, "flap_gain": 0.55,
    },
    # Day advance. The other indulgent one: pages compressing, then the covers
    # meeting. The thump is the punctuation the whole day closes on.
    "ui.ledger_close": {
        "model": "ledger", "ms": 430, "peak": -17.0, "variants": 1,
        "band": (300.0, 2600.0), "grain_hz": 180.0, "squeeze_ms": (0.0, 300.0),
        "thump_at_ms": 290.0, "thump_hz": 165.0, "thump_tau_ms": 72.0,
        "thump_gain": 1.0, "tail": (120.0, 900.0), "tail_gain": 0.22,
        "tail_tau_ms": 90.0,
    },
    # The ink blot, "with the stamp, one layer under it" (§12.4). Wet, dark and
    # the quietest thing in the set on purpose -- it must never be heard as a
    # second stamp.
    "ui.blot": {
        "model": "blot", "ms": 90, "peak": -26.0, "variants": 2,
        "band": (0.0, 900.0), "grain_hz": 140.0, "attack_ms": 1.5, "tau_ms": 40.0,
        "spatter": (1500.0, 3200.0), "spatter_gain": 0.22, "spatter_tau_ms": 22.0,
        "spatter_at_ms": 14.0,
    },
}

# docs/13 §12.4's eleven names, in the doc's own table order. `ui.silence` is
# in the list and NOT in PARAMS: it is a duck, and the mismatch is the point.
HOOKS = [
    "ui.tab", "ui.row_select", "ui.chalk", "ui.chalk_bad", "ui.stamp",
    "ui.seal", "ui.coin", "ui.page_turn", "ui.ledger_close", "ui.blot",
    "ui.silence",
]

DUCK_ONLY = {"ui.silence"}


# ---------------------------------------------------------------- render, once


def _render(hook: str, variant: int, rng: np.random.Generator) -> np.ndarray:
    p = PARAMS[hook]
    n = int(SR * p["ms"] / 1000.0)
    model = p["model"]

    if model == "paper":
        first = band(stick_slip(rng, n, p["grain_hz"]), *p["band"])
        first *= ar(n, p["attack_ms"], p["tau_ms"])
        second = band(stick_slip(rng, n, p["grain_hz"] * 0.8), *p["band"])
        second *= ar(n, p["attack_ms"], p["tau_ms"] * 0.8, p["second_ms"])
        return first + p["second_gain"] * second

    if model == "brass":
        f = p["base_hz"] * (p["detune"] ** variant)
        bar = struck([f * r for r in p["ratios"]], p["taus_ms"], p["amps"], n)
        air = band(noise(rng, n), *p["air"]) * ar(n, 0.4, p["air_tau_ms"])
        return bar + p["air_gain"] * air

    if model == "chalk":
        stroke = band(stick_slip(rng, n, p["grain_hz"]), *p["band"])
        return stroke * ar(n, p["attack_ms"], p["tau_ms"])

    if model == "stamp":
        tick = band(noise(rng, n), *p["tick"]) * ar(n, 0.1, p["tick_tau_ms"])
        body = band(stick_slip(rng, n, 900.0), *p["body"]) * ar(n, 0.6, p["body_tau_ms"])
        thump = struck([p["thump_hz"]], [p["thump_tau_ms"]], [1.0], n, 0.8)
        thump += 0.5 * band(noise(rng, n), 0.0, p["thump_hz"] * 2.0) * ar(
            n, 0.8, p["thump_tau_ms"])
        return (p["tick_gain"] * tick + p["body_gain"] * body
                + p["thump_gain"] * thump)

    if model == "seal":
        thump = struck([p["thump_hz"]], [p["thump_tau_ms"]], [1.0], n, 1.2)
        ring = struck([p["ring_hz"] * r for r in p["ratios"]], p["taus_ms"],
                      p["amps"], n, 1.0)
        wax = band(stick_slip(rng, n, 260.0), *p["wax"]) * ar(n, 2.0, p["wax_tau_ms"])
        return p["thump_gain"] * thump + ring + p["wax_gain"] * wax

    if model == "coin":
        f = p["base_hz"] * (p["detune"] ** variant)
        disc = struck([f * r for r in p["ratios"]], p["taus_ms"], p["amps"], n)
        tick = band(noise(rng, n), *p["tick"]) * ar(n, 0.1, p["tick_tau_ms"])
        return disc + p["tick_gain"] * tick

    if model == "page":
        sweep = glide_band(rng, n, p["f0"], p["f1"], p["q_oct"])
        sweep *= hump(n, *p["sweep_ms"], power=1.4)
        grab = band(stick_slip(rng, n, 520.0), p["f0"] * 0.6, p["f1"])
        grab *= hump(n, *p["grab_ms"], power=2.2)
        flap = band(noise(rng, n), 0.0, p["flap_hz"] * 2.5)
        flap *= ar(n, 1.5, p["flap_tau_ms"], p["flap_at_ms"])
        return sweep + 0.7 * grab + p["flap_gain"] * flap

    if model == "ledger":
        squeeze = band(stick_slip(rng, n, p["grain_hz"]), *p["band"])
        squeeze *= hump(n, *p["squeeze_ms"], power=1.8)
        thump = struck([p["thump_hz"]], [p["thump_tau_ms"]], [1.0], n, 1.0)
        thump = np.roll(thump, int(SR * p["thump_at_ms"] / 1000.0))
        thump[: int(SR * p["thump_at_ms"] / 1000.0)] = 0.0
        thump += 0.6 * band(noise(rng, n), 0.0, p["thump_hz"] * 3.0) * ar(
            n, 1.0, p["thump_tau_ms"], p["thump_at_ms"])
        tail = band(noise(rng, n), *p["tail"]) * ar(
            n, 3.0, p["tail_tau_ms"], p["thump_at_ms"] + 10.0)
        return squeeze + p["thump_gain"] * thump + p["tail_gain"] * tail

    if model == "blot":
        wet = band(stick_slip(rng, n, p["grain_hz"]), *p["band"])
        wet *= ar(n, p["attack_ms"], p["tau_ms"])
        spatter = band(noise(rng, n), *p["spatter"]) * ar(
            n, 0.5, p["spatter_tau_ms"], p["spatter_at_ms"])
        return wet + p["spatter_gain"] * spatter

    raise ValueError("unknown model %r for %s" % (model, hook))


def _finish(x: np.ndarray, peak_db: float) -> np.ndarray:
    """DC-remove, peak-normalise to `peak_db`, and fade both ends.

    The fades are not cosmetic: a buffer that ends mid-waveform clicks, and a
    click at the end of ui.stamp -- which fires dozens of times per raid -- is
    exactly the fatigue §12.4 warns about.
    """
    x = x - float(np.mean(x))
    m = float(np.max(np.abs(x)))
    if m > 0.0:
        x = x / m * (10.0 ** (peak_db / 20.0))
    head = min(24, x.size)           # ~0.5 ms, below the onset-perception floor
    tail = min(int(SR * 0.006), x.size)  # 6 ms out
    x[:head] *= np.linspace(0.0, 1.0, head)
    x[-tail:] *= np.linspace(1.0, 0.0, tail)
    return x


def _write_wav(path: str, x: np.ndarray) -> int:
    pcm = np.clip(np.round(x * 32767.0), -32768.0, 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return os.path.getsize(path)


def filename(hook: str, variant: int, variants: int) -> str:
    """`ui.stamp` -> ui_stamp_1.wav. The Audio autoload's HOOKS table repeats
    these names, so a rename here is a rename there."""
    stem = hook.replace(".", "_")
    return "%s.wav" % stem if variants == 1 else "%s_%d.wav" % (stem, variant + 1)


def manifest() -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for hook in HOOKS:
        if hook in DUCK_ONLY:
            continue
        n = PARAMS[hook]["variants"]
        for i in range(n):
            out.append((hook, filename(hook, i, n)))
    return out


TREE = "game/assets/audio/sfx"


def render_all(out_dir: str, quiet: bool = False) -> int:
    """Render every manifest file into `out_dir`; returns the byte total."""
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for hook in HOOKS:
        if hook in DUCK_ONLY:
            if not quiet:
                print("%-16s duck, not a sample" % hook)
            continue
        p = PARAMS[hook]
        for i in range(p["variants"]):
            seed = int.from_bytes(
                hashlib.sha256(("%s:%d" % (hook, i)).encode()).digest()[:8], "big")
            rng = np.random.default_rng(seed)
            x = _finish(_render(hook, i, rng), p["peak"])
            name = filename(hook, i, p["variants"])
            size = _write_wav(os.path.join(out_dir, name), x)
            total += size
            if not quiet:
                print("%-16s %-22s %4d ms  %6.1f dBFS  %5.1f kB"
                      % (hook, name, p["ms"], p["peak"], size / 1024.0))
    return total


def check(tree: str) -> int:
    """Re-render into a temp dir and byte-compare with `tree`.

    The same contract tools/art/gen_clouds.py --check gives build_art.sh: one
    line per file, AGREE / DIFFERS / MISSING, plus ORPHAN for a .wav in the
    tree the manifest does not name (dead weight nothing plays -- the Audio
    autoload's HOOKS table and this manifest repeat each other's filenames, so
    an orphan here is a rename that landed on one side only). Exit 1 on any.
    The temp dir is removed whatever the verdict; a DIFFERS is reproduced by
    `--out <dir>` and `cmp`, and there is nothing to keep.
    """
    tmp = tempfile.mkdtemp(prefix="gen_sfx_check_")
    rc = 0
    agree = 0
    try:
        render_all(tmp, quiet=True)
        named = set()
        for _hook, name in manifest():
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
        if os.path.isdir(tree):
            for name in sorted(os.listdir(tree)):
                if name.endswith(".wav") and name not in named:
                    print("  ORPHAN   %s/%s (in the tree, not in the manifest)" % (tree, name))
                    rc = 1
        else:
            print("  MISSING  %s (no such directory)" % tree)
            rc = 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("GEN_SFX %s  (%d agree of %d)" % ("CHECK OK" if rc == 0 else "CHECK FAILED",
                                            agree, len(manifest())))
    return rc


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default=TREE,
                    help="output directory (default: %s)" % TREE)
    ap.add_argument("--list", action="store_true",
                    help="print the manifest and exit without writing")
    ap.add_argument("--check", action="store_true",
                    help="re-render into a temp dir and byte-compare with --out; "
                         "exit 1 on any DIFFERS / MISSING / ORPHAN")
    args = ap.parse_args(argv)

    # Every hook must be accounted for: either it has a model or it is a duck.
    missing = [h for h in HOOKS if h not in PARAMS and h not in DUCK_ONLY]
    if missing:
        print("docs/13 §12.4 hooks with no model: %s" % ", ".join(missing))
        return 1

    if args.list:
        for hook, name in manifest():
            print("%-16s %s" % (hook, name))
        print("%-16s (no sample: Audio.duck(-60.0, 0.4))" % "ui.silence")
        return 0

    if args.check:
        return check(args.out)

    total = render_all(args.out)
    print("-- %d files, %.1f kB total" % (len(manifest()), total / 1024.0))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
