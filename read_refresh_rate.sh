#!/system/bin/sh
# 自动检测硬件支持的最高刷新率（优先读取 vendor 默认值）
fps=$(getprop ro.vendor.display.default_fps 2>/dev/null)
if [ -n "$fps" ] && [ "$fps" != "null" ] && [ "$fps" != "0" ]; then
    echo "$fps" | awk '{printf "%d", $1}'
    exit 0
fi
fps=$(dumpsys display 2>/dev/null | grep -oE 'supportedRefreshRates \[[^]]+\]' | grep -oE '[0-9]+\.?[0-9]*' | sort -nr | head -1)
if [ -n "$fps" ]; then
    echo "$fps" | awk '{printf "%d", $1}'
    exit 0
fi
echo 120