#!/bin/bash
# Handles Wi-Fi scanning, listing, and connecting for OmniFlyout.
#   wifi.sh list               -> JSON array of unique SSIDs with signal, in_use, security, is_locked
#   wifi.sh rescan             -> triggers a rescan
#   wifi.sh connect SSID [PWD] -> connects to network
#   wifi.sh disconnect [DEV]   -> disconnects wifi

T="timeout 6"

case "$1" in
list)
  python3 -c "
import subprocess, json

def list_wifi():
    try:
        out = subprocess.check_output(['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list'], text=True, timeout=5)
    except Exception:
        return []
    networks = {}
    for line in out.splitlines():
        parts = line.replace('\\\\:', '@@COLON@@').split(':')
        if len(parts) >= 4:
            in_use = (parts[0].strip() == '*')
            ssid = parts[1].replace('@@COLON@@', ':').strip()
            if not ssid:
                continue
            try:
                signal = int(parts[2].strip())
            except Exception:
                signal = 0
            security = parts[3].replace('@@COLON@@', ':').strip()
            is_locked = bool(security and security != '--')
            
            if ssid not in networks or in_use or signal > networks[ssid]['signal']:
                networks[ssid] = {
                    'ssid': ssid,
                    'in_use': in_use,
                    'signal': signal,
                    'security': security,
                    'is_locked': is_locked
                }
    res = list(networks.values())
    res.sort(key=lambda x: (not x['in_use'], -x['signal']))
    return res

print(json.dumps(list_wifi()))
" 2>/dev/null ;;

rescan)
  nmcli dev wifi rescan >/dev/null 2>&1
  sleep 0.5
  "$0" list ;;

connect)
  ssid="$2"
  pwd="$3"
  if [ -n "$pwd" ]; then
    nmcli dev wifi connect "$ssid" password "$pwd" 2>&1
  else
    nmcli dev wifi connect "$ssid" 2>&1
  fi ;;

disconnect)
  dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
  if [ -n "$dev" ]; then
    nmcli device disconnect "$dev" >/dev/null 2>&1
  fi ;;
esac
