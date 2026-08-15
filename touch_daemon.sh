#!/system/bin/sh
# 触控守护 - 适配 Y700 四代 + HyperOS 3.0
# 仅在 game_mode=2（游戏内）时恢复被重置的触控节点

MODDIR=$(cd "$(dirname "$0")" && pwd)
LOG_FILE="$MODDIR/apply.log"
PID_FILE="$MODDIR/daemon.pid"

if [ ! -f /proc/game_mode ] || [ ! -f /proc/HighReportRate ]; then
    echo "$(date): 触控节点缺失，守护退出" >> "$LOG_FILE"
    exit 0
fi

echo $$ > "$PID_FILE"

while true; do
    sleep 2
    GM=$(cat /proc/game_mode 2>/dev/null)
    if [ "$GM" = "2" ]; then
        HRR=$(cat /proc/HighReportRate 2>/dev/null)
        if [ "$HRR" = "High Report Rate state 1!" ]; then
            continue
        fi
        GE=$(cat /proc/game_edge 2>/dev/null)
        RT=$(cat /proc/report_threshold 2>/dev/null)
        NEED_RECOVER=0
        [ "$HRR" != "High Report Rate state 1!" ] && NEED_RECOVER=1
        [ "$GE" != "Game edge state 1!" ] && NEED_RECOVER=1
        [ "$RT" != "Report Threshold state 1!" ] && NEED_RECOVER=1

        if [ "$NEED_RECOVER" = "1" ]; then
            retry=0
            while [ $retry -lt 3 ]; do
                echo 1 > /proc/HighReportRate 2>/dev/null
                echo 1 > /proc/game_edge 2>/dev/null
                echo 1 > /proc/report_threshold 2>/dev/null
                echo 1 > /proc/gesture_control 2>/dev/null
                HRR=$(cat /proc/HighReportRate 2>/dev/null)
                GE=$(cat /proc/game_edge 2>/dev/null)
                RT=$(cat /proc/report_threshold 2>/dev/null)
                [ "$HRR" = "High Report Rate state 1!" ] && [ "$GE" = "Game edge state 1!" ] && [ "$RT" = "Report Threshold state 1!" ] && break
                retry=$((retry + 1))
            done
            echo "$(date): [recover] 游戏内节点被重置，已恢复 HRR=$HRR GE=$GE RT=$RT (重试${retry}次)" >> "$LOG_FILE"
        fi
    fi
done