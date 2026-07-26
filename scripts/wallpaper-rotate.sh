#!/usr/bin/env bash
# Rotate the active wallpaper across an image directory.
#   - selects by sequence (default, stateful) or time (hourly, stateless)
#   - sets it via WP_SETTER (default: swww img, the niri wallpaper daemon)
#   - logs + prints every change to XDG_STATE_HOME/wallpaper-rotate/log
#   - skips missing/unreadable files and unavailable setters with a clear status
# Usage: wallpaper-rotate.sh [--dir DIR] [--mode time|sequence] [--setter CMD]
set -euo pipefail

WP_DIR="${WP_DIR:-$HOME/Pictures/Wallpapers}"
WP_MODE="${WP_MODE:-sequence}"
WP_SETTER="${WP_SETTER:-swww img}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-rotate"

log() { # $1=file $2+=msg
  local f="$1"; shift
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" | tee -a "$f"
}

select_and_set() { # dir mode setter statefile logfile
  local dir="$1" mode="$2" setter="$3" state="$4" log="$5"
  local -a files
  mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>>"$log" | sort)
  ((${#files[@]})) || { log "$log" "ERROR no wallpaper files found in $dir"; return 1; }

  local idx
  if [[ "$mode" == time ]]; then
    idx=$(( ($(date +%s) / 3600) % ${#files[@]} ))   # ponytail: hourly bucket, stateless
  else
    local next=0
    [[ -f "$state" ]] && next=$(( $(<"$state") + 1 ))
    (( next >= ${#files[@]} )) && next=0
    idx=$next
    printf '%s' "$next" > "$state"
  fi

  local file="${files[$idx]}"
  [[ -r "$file" ]] || { log "$log" "ERROR selected file missing/unreadable: $file"; return 1; }
  command -v "${setter%% *}" >/dev/null 2>&1 || { log "$log" "ERROR wallpaper setter unavailable: $setter"; return 1; }

  if "$setter" "$file" 2>>"$log"; then
    log "$log" "OK set wallpaper ($mode #$idx): $file"
  else
    log "$log" "ERROR failed to set wallpaper via: $setter"
    return 1
  fi
}

run_test() {
  tmp="$(mktemp -d)"; trap "rm -rf '$tmp'" EXIT
  : > "$tmp/a.png"; : > "$tmp/b.png"; : > "$tmp/c.jpg"
  WP_DIR="$tmp"; WP_MODE=sequence; WP_SETTER="echo"
  STATE_DIR="$tmp"; mkdir -p "$STATE_DIR"
  main; main   # ponytail: exercise sequence advance twice
  [[ "$(<"$tmp/sequence")" == "1" ]] || { echo "TEST FAIL: sequence did not advance"; exit 1; }
  log "$STATE_DIR/log" "TEST OK"
}

usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; }

main() {
  mkdir -p "$STATE_DIR"
  select_and_set "$WP_DIR" "$WP_MODE" "$WP_SETTER" "$STATE_DIR/sequence" "$STATE_DIR/log"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --test) run_test; exit $?;;
    --dir) WP_DIR="$2"; shift 2;;
    --mode) WP_MODE="$2"; shift 2;;
    --setter) WP_SETTER="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; usage; exit 2;;
  esac
done

main
