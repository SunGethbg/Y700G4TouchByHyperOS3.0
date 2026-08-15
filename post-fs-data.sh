#!/system/bin/sh
# 触控优化模块 - post-fs-data (Y700 四代 + HyperOS 3.0)
# 早期设置关键属性

MODDIR=${0%/*}
LOG_FILE="$MODDIR/apply.log"

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

# 确定实际帧率
if [ "$TARGET_FPS" = "auto" ]; then
    ACTUAL_FPS=$(sh "$MODDIR/read_refresh_rate.sh" 2>/dev/null)
    [ -z "$ACTUAL_FPS" ] && ACTUAL_FPS=165
else
    ACTUAL_FPS="$TARGET_FPS"
fi

echo "$(date): touch_Y700_HyperOS post-fs-data start (fps=${ACTUAL_FPS})" > "$LOG_FILE"

# 解除帧率限制
$RESETPROP persist.sys.smartpower.limit.max.refresh.rate "$ACTUAL_FPS"
$RESETPROP persist.sys.smartpower.limit.normal.max.refresh.rate.support "$ACTUAL_FPS"
$RESETPROP persist.sys.smartpower.limit.normal.max.refresh.rate.enable false

# 游戏帧率覆盖与触控延迟
$RESETPROP ro.surface_flinger.game_default_frame_rate_override "$ACTUAL_FPS"
$RESETPROP ro.surface_flinger.set_touch_timer_ms 0

# 禁用动态刷新率优化
$RESETPROP vendor.display.enable_optimal_refresh_rate 0
$RESETPROP vendor.display.enable_idle_content_fps_hint 0
$RESETPROP ro.vendor.display.dynamic_refresh_rate ""

# 通用触控属性
$RESETPROP persist.sys.game_touch_optimization 1
$RESETPROP persist.vendor.game_touch_optimization 1
$RESETPROP persist.sys.input_latency_reduction 1
$RESETPROP persist.vendor.input_latency_mode 1
$RESETPROP persist.sys.touch_priority 1
$RESETPROP persist.vendor.touch_priority 1

echo "$(date): post-fs-data done" >> "$LOG_FILE"