#!/usr/bin/env bash
# Shoot every screen as one SHEET — a named set of rows — and lay the tiles out
# on contact sheets so a whole pass can be eyeballed in two or three images.
#
#   tools/with_godot_lock.sh ./tools/shot_all.sh [out] [--sheet=NAME] [Town,RaidView]
#
#   out           build/shots/all by default; the tiles land in <out>/<sheet>/
#                 (<Tile>.png, <Tile>.log, _sheet_N.png), one directory per
#                 sheet so contact_sheet.py's directory walk sees one sheet.
#   --sheet=NAME  which rows to shoot (default: fixture); --sheet=all runs
#                 every sheet in the order below.
#   Town,RaidView an optional filter: only tiles of those screens.
#
# The sheets (build/plan/artaudit/00-plan.md §0.3 / W0-GATE). Every row is
# one tools/shot.gd invocation at 40 frames; "fx" is the screen's own fixture
# flag from SCREENS (MainMenu is bare because it precedes any save, RaidView
# and Results carry --fixture=raid so there is a fight to report):
#
#   fixture        <Screen>            fx                               (today's 13)
#   empty          <Screen>            no fixture — the a11y "empty" sweep as images
#   new            <Screen>            --fixture=new   (W6-SHEETS: a NEW GUILD — Day 1,
#                                       the starting roster, 60 G, A0 open; the state
#                                       every Day-1 review is on, LOOP-01/LOOP-31)
#   play           <Screen>            --fixture=play  (W6-SHEETS: a LEGAL Known save a
#                                       few days in — the ladder cleared to A1, six-plus
#                                       rows on the log, two of each consumable, no "Lv."
#                                       anywhere; RaidView/Results replay the A1 clear)
#   focus          <Screen>            fx --focus                       (the ring)
#   text150        <Screen>            fx --set=text_scale=150
#   emoji          <Screen>            fx --set=emoji_free=true
#   reduced        <Screen>_motion     fx --set=reduced_motion=true
#                  <Screen>_effects    fx --set=reduced_effects=true
#   wide-keep      <Screen>            fx 1820x1024 --set=display_aspect=keep
#   wide-expand    <Screen>            fx 1820x1024 --set=display_aspect=expand
#   tabs           Guildhall_Facilities --fixture --press=Facilities
#                  Guildhall_Records    --fixture=raid:clear --press=Records
#                                       (the wall is shut at Unknown, so the
#                                       plain fixture's Records tab is disabled
#                                       and the row printed SKIPPED; the clear
#                                       is what opens it — W5-TOOLS)
#                  Tavern_Manage        --fixture --press=Manage
#                  Market_Buy           --fixture --press=Buy
#                  Market_Comfort       --fixture --press=Comfort
#   raid-advanced  RaidView_all         --fixture=raid --advance=all   (the WIPE beat)
#                  RaidView_10          --fixture=raid --advance=10
#   raid-clear     Results_clear        --fixture=raid:clear
#   hover          <Screen>_hover       one --hover=x,y per tooltip site (W6-SHEETS, UI-49's
#                                       sweep). The pixels are read off the sheets and
#                                       PINNED here; a layout change that moves a site
#                                       is found by the row's HOVER line naming the wrong
#                                       node, not by a blank plate. Per row, what is
#                                       under the pointer today:
#                  RaiderDetail_hover   --fixture 584,167       a worn-gear cell: the kit's
#                                                              two-line plate (180x56)
#                  Tavern_hover         --fixture 237,787       a candidate's "arrives with"
#                                                              cell — EMPTY: no recruit is
#                                                              dressed (Recruitment.gear_plan
#                                                              has no caller), so no plate
#                  Market_hover         --fixture=play 290,350  the Sell window's first find
#                                                              (the reference fixture has no
#                                                              loot): Godot's one-line plate
#                  AdventureBoard_hover --fixture 1197,375      the notice's reward slot: no
#                                                              tooltip on it today
#                  RaidView_hover       --fixture=raid 176,908  a party card's head cell:
#                                                              Godot's one-line plate
#                                       (handoff-W6-SHEETS asks the three plain-text sites
#                                       for `Widgets.tooltip_for`, and the reward slot for
#                                       any tooltip at all)
#
# A row whose flag this worktree's tools/shot.gd does not know prints SKIPPED
# and does not fail the sheet: shot.gd grows those flags in W0-SHOT, and a
# wave must be green in isolation. The check is a grep for the flag's spelling
# in tools/shot.gd, because today's shot.gd does not reject an unknown flag —
# it appends it to the positional list and shoots a plain screen, which would
# put a lie on the sheet. An exit 2 from shot.gd (usage) is SKIPPED as well,
# and so is exit 12 — a --press target the row's fixture leaves disabled
# (Records at Unknown): shot.gd's reason is echoed on the row. Any other
# failure prints FAIL, keeps the log, and the script exits 1.
#
# Do not edit this file while a run of it is in progress: bash reads a script
# as it executes, and an edit moved the running copy's exit status once.
#
# THE LOCK: Godot must never run twice in this project at once. The script is
# meant to be wrapped (the grammar above); run bare, it wraps itself. The lock
# is not re-entrant, so it looks for a with_godot_lock.sh ancestor first.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

under_godot_lock() {
  local pid=$$
  while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    if tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q "with_godot_lock"; then
      return 0
    fi
    pid=$(cat "/proc/$pid/ppid" 2>/dev/null) || return 1
  done
  return 1
}
if ! under_godot_lock; then
  exec tools/with_godot_lock.sh "$0" "$@"
fi

source tools/env.sh

OUT="build/shots/all"
SHEET="fixture"
ONLY=""
first=1
for a in "$@"; do
  case "$a" in
    --sheet=*) SHEET="${a#--sheet=}" ;;
    --only=*)  ONLY="${a#--only=}" ;;
    --*)       echo "shot_all: unknown flag $a" >&2; exit 2 ;;
    *) if [ "$first" = 1 ]; then OUT="$a"; first=0; else ONLY="$a"; fi ;;
  esac
done

ALL_SHEETS="fixture empty new play focus text150 emoji reduced wide-keep wide-expand tabs raid-advanced raid-clear hover"

# name|fixture flag ("-" for none)
SCREENS=(
  "MainMenu|-"
  "Town|--fixture"
  "AdventureBoard|--fixture"
  "RaidPrep|--fixture"
  "RaidView|--fixture=raid"
  "Results|--fixture=raid"
  "Guildhall|--fixture"
  "RaiderDetail|--fixture"
  "Tavern|--fixture"
  "Market|--fixture"
  "LoadSave|--fixture"
  "Settings|--fixture"
  "Completion|--fixture"
)

# Rows of one sheet: "tile|screen|WxH|flags" (flags space-separated, may be empty).
rows_for() {
  local sheet="$1" n f fx
  case "$sheet" in
    fixture|empty|new|play|focus|text150|emoji|reduced|wide-keep|wide-expand)
      for s in "${SCREENS[@]}"; do
        IFS="|" read -r n f <<< "$s"
        fx=""; [ "$f" != "-" ] && fx="$f"
        case "$sheet" in
          fixture)     echo "$n|$n|1536x1024|$fx" ;;
          empty)       echo "$n|$n|1536x1024|" ;;
          # Every route, the MainMenu included: on `play` a save exists (the
          # clears autosaved), which is the menu a returning player sees.
          new)         echo "$n|$n|1536x1024|--fixture=new" ;;
          play)        echo "$n|$n|1536x1024|--fixture=play" ;;
          focus)       echo "$n|$n|1536x1024|$fx --focus" ;;
          text150)     echo "$n|$n|1536x1024|$fx --set=text_scale=150" ;;
          emoji)       echo "$n|$n|1536x1024|$fx --set=emoji_free=true" ;;
          reduced)     echo "${n}_motion|$n|1536x1024|$fx --set=reduced_motion=true"
                       echo "${n}_effects|$n|1536x1024|$fx --set=reduced_effects=true" ;;
          wide-keep)   echo "$n|$n|1820x1024|$fx --set=display_aspect=keep" ;;
          wide-expand) echo "$n|$n|1820x1024|$fx --set=display_aspect=expand" ;;
        esac
      done ;;
    tabs)
      echo "Guildhall_Facilities|Guildhall|1536x1024|--fixture --press=Facilities"
      echo "Guildhall_Records|Guildhall|1536x1024|--fixture=raid:clear --press=Records"
      echo "Tavern_Manage|Tavern|1536x1024|--fixture --press=Manage"
      echo "Market_Buy|Market|1536x1024|--fixture --press=Buy"
      echo "Market_Comfort|Market|1536x1024|--fixture --press=Comfort" ;;
    raid-advanced)
      echo "RaidView_all|RaidView|1536x1024|--fixture=raid --advance=all"
      echo "RaidView_10|RaidView|1536x1024|--fixture=raid --advance=10" ;;
    raid-clear)
      echo "Results_clear|Results|1536x1024|--fixture=raid:clear" ;;
    hover)
      echo "RaiderDetail_hover|RaiderDetail|1536x1024|--fixture --hover=584,167"
      echo "Tavern_hover|Tavern|1536x1024|--fixture --hover=237,787"
      echo "Market_hover|Market|1536x1024|--fixture=play --hover=290,350"
      echo "AdventureBoard_hover|AdventureBoard|1536x1024|--fixture --hover=1197,375"
      echo "RaidView_hover|RaidView|1536x1024|--fixture=raid --hover=176,908" ;;
    *)
      echo "shot_all: unknown sheet '$sheet' (one of: $ALL_SHEETS, all)" >&2
      return 2 ;;
  esac
}

# The first flag in "$@" whose spelling tools/shot.gd does not contain, else
# nothing. Flags shot.gd has always had (--fixture, --fixture=raid,
# --completed, --set=<other keys>) are never reported.
unsupported_flag() {
  local flag needle
  for flag in "$@"; do
    case "$flag" in
      --focus)                 needle="--focus" ;;
      --tab=*)                 needle="--tab=" ;;
      --press=*)               needle="--press=" ;;
      --advance=*)             needle="--advance=" ;;
      --fixture=raid:clear)    needle="raid:clear" ;;
      --fixture=new)           needle="fixture=new" ;;
      --fixture=play)          needle="fixture=play" ;;
      --set=display_aspect=*)  needle="display_aspect" ;;
      --frames=*)              needle="--frames=" ;;
      --hold-boot)             needle="--hold-boot" ;;
      --hover=*)               needle="--hover=" ;;
      *) continue ;;
    esac
    if ! grep -qF -- "$needle" tools/shot.gd; then
      echo "$flag"; return 0
    fi
  done
  return 0
}

shoot_sheet() {
  local sheet="$1" dir="$OUT/$1" tile screen size flags missing rc why
  local n_ok=0 n_skip=0 n_fail=0
  local rows
  rows=$(rows_for "$sheet") || return 2
  mkdir -p "$dir"
  printf 'sheet %s -> %s\n' "$sheet" "$dir"
  while IFS="|" read -r tile screen size flags; do
    [ -z "$tile" ] && continue
    if [ -n "$ONLY" ] && [[ ",$ONLY," != *",$screen,"* ]] && [[ ",$ONLY," != *",$tile,"* ]]; then
      continue
    fi
    # shellcheck disable=SC2086
    missing=$(unsupported_flag $flags)
    if [ -n "$missing" ]; then
      printf '  SKIPPED %-22s (tools/shot.gd lacks %s)\n' "$tile" "$missing"
      n_skip=$((n_skip + 1)); rm -f "$dir/$tile.png"; continue
    fi
    # shellcheck disable=SC2086
    timeout 200 "$GODOT" -w --path . --script res://tools/shot.gd -- \
      "res://game/screens/$screen.tscn" "$dir/$tile.png" 40 "$size" $flags \
      > "$dir/$tile.log" 2>&1
    rc=$?
    if [ "$rc" = 0 ]; then
      printf '  ok      %s\n' "$tile"; n_ok=$((n_ok + 1))
    elif [ "$rc" = 2 ]; then
      printf '  SKIPPED %-22s (shot.gd usage exit 2; see %s/%s.log)\n' "$tile" "$dir" "$tile"
      n_skip=$((n_skip + 1)); rm -f "$dir/$tile.png"
    elif [ "$rc" = 12 ]; then
      # --press found the Button and it is disabled under this row's fixture
      # (shot.gd exit 12): a player could not press it either, so there is no
      # surface to shoot yet. shot.gd's reason is echoed so nothing is hidden;
      # the row lights up when the fixture reaches the state (Records: Known).
      why=$(grep -o "is disabled.*" "$dir/$tile.log" | head -1)
      printf '  SKIPPED %-22s (press target %s)\n' "$tile" "${why:-is disabled (exit 12)}"
      n_skip=$((n_skip + 1)); rm -f "$dir/$tile.png"
    else
      printf '  \033[31mFAIL\033[0m    %s (exit %s, see %s/%s.log)\n' "$tile" "$rc" "$dir" "$tile"
      n_fail=$((n_fail + 1))
    fi
  done <<< "$rows"
  if [ "$n_ok" -gt 0 ]; then
    python tools/art/contact_sheet.py "$dir" || n_fail=$((n_fail + 1))
  else
    printf '  (nothing rendered for sheet %s: no contact sheet)\n' "$sheet"
  fi
  printf 'sheet %s: %d ok, %d skipped, %d failed\n' "$sheet" "$n_ok" "$n_skip" "$n_fail"
  [ "$n_fail" = 0 ]
}

RC=0
if [ "$SHEET" = "all" ]; then
  for s in $ALL_SHEETS; do shoot_sheet "$s" || RC=1; done
else
  shoot_sheet "$SHEET" || RC=$?   # 1 = a row failed, 2 = unknown sheet
fi
exit $RC
