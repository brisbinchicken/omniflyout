#!/bin/bash
# Handles Bluetooth device listing, scanning, and connection management for OmniFlyout.
#   bluetooth.sh list               -> JSON array of devices
#   bluetooth.sh rescan             -> triggers a scan then returns list
#   bluetooth.sh connect <MAC>      -> connects to device
#   bluetooth.sh disconnect <MAC>   -> disconnects device
#   bluetooth.sh pair <MAC>         -> pairs with device
#   bluetooth.sh alias              -> returns controller alias

case "$1" in
alias)
  bluetoothctl show | awk -F': ' '/Alias:/ {print $2; exit}'
  ;;

list)
  python3 -c "
import subprocess, re, json

def get_devices():
    # 1. Paired devices
    paired_macs = set()
    try:
        p = subprocess.run(['bluetoothctl', 'devices', 'Paired'], capture_output=True, text=True, timeout=3)
        paired_lines = p.stdout.strip().splitlines()
    except Exception:
        paired_lines = []

    devices_dict = {}

    for line in paired_lines:
        parts = line.split(' ', 2)
        if len(parts) >= 3:
            mac = parts[1]
            name = parts[2]
            paired_macs.add(mac)
            devices_dict[mac] = {
                'mac': mac,
                'name': name,
                'paired': True,
                'connected': False,
                'icon': 'bluetooth.svg',
                'raw_icon': '',
                'battery': None
            }

    # 2. All known devices (including discovered unpaired if any)
    try:
        p2 = subprocess.run(['bluetoothctl', 'devices'], capture_output=True, text=True, timeout=3)
        all_lines = p2.stdout.strip().splitlines()
    except Exception:
        all_lines = []

    for line in all_lines:
        parts = line.split(' ', 2)
        if len(parts) >= 3:
            mac = parts[1]
            name = parts[2]
            if mac not in devices_dict:
                devices_dict[mac] = {
                    'mac': mac,
                    'name': name,
                    'paired': False,
                    'connected': False,
                    'icon': 'bluetooth.svg',
                    'raw_icon': '',
                    'battery': None
                }

    # 3. For each device, fetch status details
    for mac, d in list(devices_dict.items()):
        try:
            info_p = subprocess.run(['bluetoothctl', 'info', mac], capture_output=True, text=True, timeout=1.5)
            info_txt = info_p.stdout
        except Exception:
            info_txt = ''

        d['connected'] = ('Connected: yes' in info_txt)
        
        # Raw icon
        icon_match = re.search(r'Icon:\s*(\S+)', info_txt)
        raw_icon = icon_match.group(1).lower() if icon_match else ''
        d['raw_icon'] = raw_icon

        # Map to SVG icon
        name_lower = d['name'].lower()
        if 'headset' in raw_icon or 'headphone' in raw_icon or 'airpod' in name_lower or 'wh-1000' in name_lower:
            d['icon'] = 'headphones.svg'
        elif 'speaker' in raw_icon or 'audio' in raw_icon or 'loud' in name_lower:
            d['icon'] = 'speaker.svg'
        elif 'keyboard' in raw_icon or 'keychron' in name_lower or 'k250' in name_lower or 'logi k' in name_lower:
            d['icon'] = 'keyboard.svg'
        elif 'mouse' in raw_icon or 'mx master' in name_lower:
            d['icon'] = 'mouse.svg'
        elif 'phone' in raw_icon:
            d['icon'] = 'device-tablet.svg'
        else:
            d['icon'] = 'bluetooth.svg'

        # Battery percentage
        batt_match = re.search(r'Battery Percentage:\s*0x[0-9a-fA-F]+\s*\((\d+)\)', info_txt)
        if not batt_match:
            batt_match = re.search(r'Battery Percentage:\s*(\d+)', info_txt)
        if batt_match:
            d['battery'] = int(batt_match.group(1))

    dev_list = list(devices_dict.values())
    dev_list.sort(key=lambda x: (not x['connected'], not x['paired'], x['name'].lower()))
    return dev_list

print(json.dumps(get_devices()))
" 2>/dev/null
  ;;

rescan)
  # Trigger scan in background for 4 seconds then list
  bluetoothctl --timeout 4 scan on >/dev/null 2>&1
  "$0" list
  ;;

connect)
  mac="$2"
  if [ -n "$mac" ]; then
    bluetoothctl connect "$mac" 2>&1
  fi
  ;;

disconnect)
  mac="$2"
  if [ -n "$mac" ]; then
    bluetoothctl disconnect "$mac" 2>&1
  fi
  ;;

pair)
  mac="$2"
  if [ -n "$mac" ]; then
    bluetoothctl pair "$mac" 2>&1
  fi
  ;;
esac
