#!/system/bin/sh
# 刷新率变化监控与 480Hz 触控恢复
# 当屏幕刷新率改变时，重新应用触控节点
# 可选：重新绑定驱动以强制重载固件（请根据实际驱动名修改）

MODDIR=$(cd "$(dirname "$0")" && pwd)
LOG="$MODDIR/refresh_monitor.log"

echo "$(date): 刷新率监控启动" > "$LOG"
last_fps=""

while true; do
    current_fps=$(dumpsys display 2>/dev/null | grep -oE 'fps=[0-9]+\.?[0-9]*' | head -1 | sed 's/fps=//' | awk '{printf "%d", $1}')
    [ -z "$current_fps" ] && current_fps=120

    if [ "$current_fps" != "$last_fps" ]; then
        echo "$(date): 刷新率变化 $last_fps -> $current_fps，重新应用触控配置" >> "$LOG"

        [ -f /proc/HighReportRate ] && echo 1 > /proc/HighReportRate 2>/dev/null
        [ -f /proc/game_edge ] && echo 1 > /proc/game_edge 2>/dev/null
        [ -f /proc/report_threshold ] && echo 1 > /proc/report_threshold 2>/dev/null
        [ -f /proc/gesture_control ] && echo 1 > /proc/gesture_control 2>/dev/null

        # 可选：重新绑定驱动（示例，请先手动验证后启用）
        # echo -n "2-005b" > /sys/bus/i2c/drivers/NVT-ts/unbind 2>/dev/null
        # sleep 0.1
        # echo -n "2-005b" > /sys/bus/i2c/drivers/NVT-ts/bind 2>/dev/null

        last_fps="$current_fps"
    fi
    sleep 1
done