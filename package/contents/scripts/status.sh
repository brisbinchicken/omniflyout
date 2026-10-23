#!/bin/bash
# Prints key=value lines describing the system state. Read by main.qml.
# Every external call has a timeout so one stuck tool can never freeze the widget.
cache="$HOME/.cache/omniflyout"
T="timeout 2"

# ---- Real Physical IP (strictly filtering out VPNs, bridges, docker, virtual interfaces)
phys_ip=""
phys_type=""
phys_dev=""

def_dev=$(ip route 2>/dev/null | awk '$1=="default" && $2=="via"{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
case "$def_dev" in
  tun*|wg*|tailscale*|docker*|br-*|virbr*|veth*|lo) def_dev="" ;;
esac

if [ -z "$def_dev" ]; then
  def_dev=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$3=="connected" && ($2=="ethernet" || $2=="wifi"){print $1; exit}')
fi

if [ -n "$def_dev" ]; then
  phys_dev="$def_dev"
  phys_ip=$(ip -4 addr show "$def_dev" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)
  t=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: -v d="$def_dev" '$1==d{print $2; exit}')
  if [ "$t" = "ethernet" ]; then
    phys_type="Ethernet"
  elif [ "$t" = "wifi" ]; then
    phys_type="Wi-Fi"
  else
    phys_type="Wired"
  fi
fi

echo "ip=$phys_ip"
echo "iptype=$phys_type"
echo "ipdev=$phys_dev"

# ---- Wi-Fi
echo "wifi=$($T nmcli radio wifi 2>/dev/null)"
if $T nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^wifi:connected'; then
  echo "wificonn=1"
  ssid=$($T nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$1=="wifi" && $2=="connected"{print $3; exit}')
  echo "ssid=$ssid"
else
  echo "wificonn=0"; echo "ssid="
fi

# ---- Ethernet: prefer a connected wired device, otherwise the first managed one
devs=$($T nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$2=="ethernet" && $3!="unmanaged"')
eth=$(echo "$devs" | awk -F: '$3=="connected"{print; exit}')
[ -z "$eth" ] && eth=$(echo "$devs" | head -n1)
if [ -n "$eth" ]; then
  dev=$(echo "$eth" | cut -d: -f1)
  speed=$(cat "/sys/class/net/$dev/speed" 2>/dev/null)
  echo "eth=$eth"
  echo "ethspeed=${speed:-}"
else
  echo "eth="
fi

# ---- Bluetooth
if [ -n "$(ls /sys/class/bluetooth 2>/dev/null)" ]; then
  if $T bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo "bt=on"; else echo "bt=off"; fi
  n=$($T bluetoothctl devices Connected 2>/dev/null | grep -c '^Device')
  echo "btcount=${n:-0}"
else
  echo "bt=off"; echo "btcount=0"
fi

# ---- Volume + microphone
v=$($T wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
echo "vol=$(echo "$v" | awk '{print $2}')"
case "$v" in *MUTED*) echo "muted=1" ;; *) echo "muted=0" ;; esac
case "$($T wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)" in *MUTED*) echo "micmuted=1" ;; *) echo "micmuted=0" ;; esac

# ---- Audio devices
echo "defsink=$($T pactl get-default-sink 2>/dev/null)"
echo "defsource=$($T pactl get-default-source 2>/dev/null)"
echo "sinks=$($T pactl -f json list sinks 2>/dev/null | tr -d '\n')"
echo "sources=$($T pactl -f json list sources 2>/dev/null | tr -d '\n')"

# ---- Caffeine
if [ -f "$cache/caffeine.pid" ] && kill -0 "$(cat "$cache/caffeine.pid")" 2>/dev/null; then echo "caffeine=1"; else echo "caffeine=0"; fi

# ---- DND
inh=$($T busctl --user get-property org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Inhibited 2>/dev/null | awk '{print $2}')
if [ "$inh" = "true" ]; then echo "dnd=1"; else echo "dnd=0"; fi

# ---- Night light
echo "night=$($T kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null)"

# ---- Dark mode
bg=$($T kreadconfig6 --file kdeglobals --group Colors:Window --key BackgroundNormal 2>/dev/null)
IFS=, read -r r g b <<< "$bg"
if [ -n "$r" ] && [ $(( (${r:-255}*299 + ${g:-255}*587 + ${b:-255}*114) / 1000 )) -lt 128 ]; then echo "dark=1"; else echo "dark=0"; fi

# ---- Airplane
n=$($T rfkill -n -o SOFT list 2>/dev/null | grep -c .)
un=$($T rfkill -n -o SOFT list 2>/dev/null | grep -c '^unblocked')
if [ "$n" -gt 0 ] && [ "$un" -eq 0 ]; then echo "airplane=1"; else echo "airplane=0"; fi

# ---- Power profile
echo "profile=$($T powerprofilesctl get 2>/dev/null)"

# ---- Media
if command -v playerctl >/dev/null 2>&1; then
  sel=""
  for p in $($T playerctl -l 2>/dev/null); do
    st=$(timeout 1 playerctl -p "$p" status 2>/dev/null)
    if [ "$st" = "Playing" ]; then sel="$p"; break; fi
    if [ "$st" = "Paused" ] && [ -z "$sel" ]; then sel="$p"; fi
  done
  if [ -n "$sel" ]; then
    echo "player=$sel"
    echo "media=$(timeout 2 playerctl -p "$sel" metadata --format '{{status}}|||{{artist}}|||{{title}}|||{{mpris:artUrl}}|||{{position}}|||{{mpris:length}}' 2>/dev/null | head -n1)"
  fi
  echo "playerctl=1"
else
  echo "playerctl=0"
fi
