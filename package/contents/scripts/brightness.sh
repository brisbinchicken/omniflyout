#!/bin/bash
# Built-in (laptop) screen brightness only. External monitors are ignored on purpose.
#   brightness.sh list            -> "name|current|max" for the internal panel (nothing if there is none)
#   brightness.sh set NAME VALUE  -> set raw brightness
svc=org.kde.ScreenBrightness
bus() { timeout 3 busctl --user "$@" 2>/dev/null; }

case "$1" in
list)
  for n in $(bus get-property $svc /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames | grep -o '"[^"]*"' | tr -d '"'); do
    p=/org/kde/ScreenBrightness/$n
    internal=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display IsInternal | awk '{print $2}')
    [ "$internal" = "true" ] || continue
    cur=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display Brightness | awk '{print $2}')
    max=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display MaxBrightness | awk '{print $2}')
    echo "$n|${cur:-0}|${max:-100}"
    exit 0
  done
  # fallback: Plasma service unavailable -> brightnessctl reads the backlight device directly
  if command -v brightnessctl >/dev/null 2>&1; then
    brightnessctl -m -c backlight 2>/dev/null | head -n1 | awk -F, '{print "brightnessctl|" $3 "|" $5}'
  fi ;;
set)
  case "$2" in
    brightnessctl) brightnessctl -c backlight set "$3" >/dev/null 2>&1 ;;
    *) bus call $svc "/org/kde/ScreenBrightness/$2" org.kde.ScreenBrightness.Display SetBrightness iu "$3" 1 >/dev/null ;;
  esac ;;
esac
