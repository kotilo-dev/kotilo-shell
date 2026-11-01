#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# One reading of the machine, in === sections, for the System tab. Read-only. Pass "nvidia" to query
# an NVIDIA card: nvidia-smi wakes a sleeping one, so it runs only when asked and only when awake.
section() { echo "=== $1"; }

section meminfo; cat /proc/meminfo
section loadavg; cat /proc/loadavg
section uptime; cat /proc/uptime
section cpufreq; grep '^cpu MHz' /proc/cpuinfo
section cpumodel; grep -m1 '^model name' /proc/cpuinfo
section diskstats; cat /proc/diskstats
section df; df -B1 --output=source,target,size,used -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs 2>/dev/null
section net
for dev in /sys/class/net/*; do
    name=${dev##*/}
    [ "$name" = lo ] && continue
    echo "$name $(cat "$dev/operstate" 2>/dev/null) $(cat "$dev/statistics/rx_bytes" 2>/dev/null) $(cat "$dev/statistics/tx_bytes" 2>/dev/null)"
done
section temps
for mon in /sys/class/hwmon/hwmon*; do
    [ -r "$mon/temp1_input" ] && echo "$(cat "$mon/name" 2>/dev/null) $(cat "$mon/temp1_input" 2>/dev/null)"
done
section gpus
for card in /sys/class/drm/card[0-9]; do
    [ -e "$card/device" ] || continue
    slot=$(sed -n 's/^PCI_SLOT_NAME=//p' "$card/device/uevent" 2>/dev/null)
    driver=$(basename "$(readlink "$card/device/driver" 2>/dev/null)")
    name=$(lspci -s "$slot" 2>/dev/null | sed 's/^[^:]*: *[^:]*: *//')
    state=$(cat "$card/device/power/runtime_status" 2>/dev/null)
    busy=$(cat "$card/device/gpu_busy_percent" 2>/dev/null)
    used=$(cat "$card/device/mem_info_vram_used" 2>/dev/null)
    total=$(cat "$card/device/mem_info_vram_total" 2>/dev/null)
    freq=$(cat "$card/gt_cur_freq_mhz" 2>/dev/null)
    max=$(cat "$card/gt_max_freq_mhz" 2>/dev/null)
    smi=""
    if [ "$driver" = nvidia ] && [ "$1" = nvidia ] && [ "$state" != suspended ]; then
        smi=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    fi
    echo "$driver|$state|$busy|$used|$total|$freq|$max|$smi|$name"
done
