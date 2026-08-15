#!/system/bin/sh
# ============================================================
# 触控优化模块 - service.sh (Y700 四代 + HyperOS 3.0)
# 功能：
#   - 写入触控增强节点（不写 game_mode）
#   - 解除帧率限制，设置游戏帧率覆盖
#   - 禁用动态刷新率优化，保持触控模式稳定
#   - 启动触控守护（游戏内恢复节点）
#   - 启动刷新率监控（全刷新率 480Hz 适配）
#   - 创建 /Hyw.log 符号链接，启动 WebUI 日志查看服务
# ============================================================

MODDIR=${0%/*}
LOG_FILE="$MODDIR/apply.log"
PID_FILE="$MODDIR/daemon.pid"

# 读取配置
CONFIG_FILE="$MODDIR/config"
TARGET_FPS="auto"
if [ -f "$CONFIG_FILE" ]; then
    TARGET_FPS=$(sed -n 's/^fps=\(.*\)/\1/p' "$CONFIG_FILE" 2>/dev/null | head -1)
    [ -z "$TARGET_FPS" ] && TARGET_FPS="auto"
fi

# 重置属性工具
RESETPROP=""
for rp in /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop /system/bin/resetprop; do
    [ -x "$rp" ] && RESETPROP="$rp" && break
done
[ -z "$RESETPROP" ] && RESETPROP="resetprop"

# 等待系统启动完成
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
sleep 10

# 确定实际帧率
if [ "$TARGET_FPS" = "auto" ]; then
    ACTUAL_FPS=$(sh "$MODDIR/read_refresh_rate.sh" 2>/dev/null)
    [ -z "$ACTUAL_FPS" ] && ACTUAL_FPS=165
else
    ACTUAL_FPS="$TARGET_FPS"
fi

echo "$(date): ========== touch_Y700_HyperOS v2.0 start (fps=${ACTUAL_FPS}) ==========" > "$LOG_FILE"

# ============================================================
# 1. 写入触控增强节点（不写 game_mode）
# ============================================================
if [ -f /proc/HighReportRate ]; then
    echo 1 > /proc/HighReportRate 2>/dev/null
    echo "$(date): [boot] HighReportRate=$(cat /proc/HighReportRate 2>/dev/null)" >> "$LOG_FILE"
fi
if [ -f /proc/game_edge ]; then
    echo 1 > /proc/game_edge 2>/dev/null
    echo "$(date): [boot] game_edge=$(cat /proc/game_edge 2>/dev/null)" >> "$LOG_FILE"
fi
if [ -f /proc/report_threshold ]; then
    echo 1 > /proc/report_threshold 2>/dev/null
    echo "$(date): [boot] report_threshold=$(cat /proc/report_threshold 2>/dev/null)" >> "$LOG_FILE"
fi
if [ -f /proc/gesture_control ]; then
    echo 1 > /proc/gesture_control 2>/dev/null
fi

# ============================================================
# 2. 框架层属性设置
# ============================================================
$RESETPROP persist.sys.smartpower.limit.max.refresh.rate "$ACTUAL_FPS"
$RESETPROP persist.sys.smartpower.limit.normal.max.refresh.rate.support "$ACTUAL_FPS"
$RESETPROP persist.sys.smartpower.limit.normal.max.refresh.rate.enable false
$RESETPROP ro.surface_flinger.game_default_frame_rate_override "$ACTUAL_FPS"
$RESETPROP ro.surface_flinger.set_touch_timer_ms 0
$RESETPROP vendor.display.enable_optimal_refresh_rate 0
$RESETPROP vendor.display.enable_idle_content_fps_hint 0
$RESETPROP persist.sys.game_touch_optimization 1
$RESETPROP persist.vendor.game_touch_optimization 1
$RESETPROP persist.sys.input_latency_reduction 1
$RESETPROP persist.vendor.input_latency_mode 1
$RESETPROP persist.sys.touch_priority 1
$RESETPROP persist.vendor.touch_priority 1

# ============================================================
# 3. 启动触控守护（游戏内恢复节点）
# ============================================================
TOUCH_DAEMON="$MODDIR/touch_daemon.sh"
chmod 755 "$TOUCH_DAEMON" 2>/dev/null
setsid nohup "$TOUCH_DAEMON" >/dev/null 2>&1 &
echo "$(date): 触控守护已启动 PID=$!" >> "$LOG_FILE"

# ============================================================
# 4. 启动刷新率监控（全刷新率 480Hz 适配）
# ============================================================
REFRESH_MONITOR="$MODDIR/refresh_monitor.sh"
chmod 755 "$REFRESH_MONITOR" 2>/dev/null
setsid nohup "$REFRESH_MONITOR" >/dev/null 2>&1 &
echo "$(date): 刷新率监控已启动 PID=$!" >> "$LOG_FILE"

# ============================================================
# 5. 创建 /Hyw.log 符号链接（指向模块的 apply.log）
# ============================================================
ln -sf "$LOG_FILE" /Hyw.log 2>/dev/null

# ============================================================
# 6. 启动 WebUI 服务（端口 8080，用于查看日志）
# ============================================================
chmod -R 755 "$MODDIR/webroot" 2>/dev/null
HTTPD_PORT=8080
if command -v busybox >/dev/null 2>&1; then
    if ! busybox netstat -an | grep -q ":$HTTPD_PORT .*LISTEN"; then
        busybox httpd -p $HTTPD_PORT -h "$MODDIR/webroot" -c "$MODDIR/webroot/httpd.conf" >/dev/null 2>&1 &
        echo "$(date): 日志 WebUI 已启动，端口 $HTTPD_PORT" >> "$LOG_FILE"
    fi
else
    echo "$(date): 未找到 busybox，WebUI 不可用" >> "$LOG_FILE"
fi

# ============================================================
# 结束
# ============================================================
echo "$(date): service.sh 执行完毕" >> "$LOG_FILE"