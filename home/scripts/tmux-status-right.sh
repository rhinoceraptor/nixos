#!/usr/bin/env bash
# tmux status-right: battery indicator + clock.
# Packaged via pkgs.writeShellApplication in home/common.nix, which adds its
# own shebang and `set -euo pipefail`; the ones here are just so this file
# can be run and linted directly during development.
set -euo pipefail

battery() {
  local BATTERY="🔋️" CHARGER="🔌️" PERCENTAGE="" STATE="" EXTRA="     "

  if [[ "$(uname)" == "Linux" ]]; then
    local BAT_PATH UPOWER
    # head -n1: some laptops report multiple BATx devices; upower -i
    # only accepts a single path, so just use the first battery.
    BAT_PATH=$(upower -e | grep 'BAT' | head -n1 || true)
    [[ -z "$BAT_PATH" ]] && return
    UPOWER=$(upower -i "$BAT_PATH")

    # Exact field match: "$1 == f" avoids energy: matching energy-full: etc.
    getfield() { echo "$UPOWER" | awk -v f="$1" '$1 == f { print $2 }'; }

    PERCENTAGE=$(getfield "percentage:")
    local RAW_STATE RATE
    RAW_STATE=$(getfield "state:")
    RATE=$(getfield "energy-rate:")

    # pending-discharge (not yet actively drawing from the battery)
    # counts as discharging too; everything else (charging,
    # fully-charged, pending-charge, unknown, empty) shows the plug.
    if [[ "$RAW_STATE" == "discharging" || "$RAW_STATE" == "pending-discharge" ]]; then
      STATE="$BATTERY"
      local ENERGY
      ENERGY=$(getfield "energy:")
      # Time remaining = energy / rate; round to nearest 5 min
      EXTRA=$(awk -v e="$ENERGY" -v r="$RATE" 'BEGIN {
        if (r+0 == 0) { printf "     "; exit }
        m = e / r * 60
        rounded = int((m + 2.5) / 5) * 5
        printf "%2d:%02d", int(rounded / 60), rounded % 60
      }')
    else
      STATE="$CHARGER"
      EXTRA=$(awk -v r="$RATE" 'BEGIN {
        if (r+0 == 0) { printf "     "; exit }
        printf "%4.0fW", r
      }')
    fi

  elif [[ "$(uname)" == "Darwin" ]]; then
    local POWER
    POWER=$(pmset -g batt)
    PERCENTAGE=$(echo "$POWER" | grep -oE "[0-9]{2,3}%")
    if echo "$POWER" | grep -q "Battery Power"; then
      STATE="$BATTERY"
    else
      STATE="$CHARGER"
    fi

    # pmset already computes its own time-to-empty/time-to-full
    # estimate; reuse it since macOS doesn't expose a plain watt rate
    # the way upower does.
    local TIME_RAW
    TIME_RAW=$(echo "$POWER" | grep -oE "[0-9]+:[0-9]{2} remaining" || true)
    if [[ -n "$TIME_RAW" ]]; then
      EXTRA=$(echo "${TIME_RAW% remaining}" | awk -F: '{ printf "%2d:%02d", $1, $2 }')
    fi
  fi

  if [[ -n "$PERCENTAGE" && -n "$STATE" ]]; then
    local COLOR=""
    case $PERCENTAGE in
      100%|9[0-9]%|8[0-9]%|7[0-9]%) COLOR="#[bg=#98c379]#[fg=#2a2f39]" ;;
      6[0-9]%|5[0-9]%|4[0-9]%|3[0-9]%) COLOR="#[bg=#e5c07b]#[fg=#2a2f39]" ;;
      2[0-9]%|1[0-9]%|[0-9]%) COLOR="#[bg=#e06c75]#[fg=#2a2f39]" ;;
    esac
    printf "%s " "$COLOR $PERCENTAGE $STATE $EXTRA #[default]"
  fi
}

battery
printf "%s" "$(date +'%a %b %d %I:%M %p') "
