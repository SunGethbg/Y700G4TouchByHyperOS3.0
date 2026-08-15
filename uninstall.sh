#!/system/bin/sh
# 触控优化模块卸载清理
# ============================================================

MODDIR=${0%/*}
RP=""
for rp in /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop /system/bin/resetprop; do
    [ -x "$rp" ] && RP="$rp" && break
done
[ -z "$RP" ] && RP="resetprop"

echo "$(date): ===== 触控优化模块卸载清理 ====="

# 停止守护和监控
[ -f "$MODDIR/daemon.pid" ] && kill "$(cat "$MODDIR/daemon.pid")" 2>/dev/null
pkill -f "refresh_monitor.sh" 2>/dev/null
for pid in $(ls /proc | grep -E '^[0-9]+$'); do
    case "$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')" in
        *touch_daemon.sh*|*refresh_monitor.sh*) kill -9 "$pid" 2>/dev/null ;;
    esac
done
echo "已停止后台守护与监控"

# 删除覆写的 persist 属性
for p in \
    persist.sys.game_touch_optimization \
    persist.vendor.game_touch_optimization \
    persist.sys.input_latency_reduction \
    persist.vendor.input_latency_mode \
    persist.sys.touch_priority \
    persist.vendor.touch_priority \
    persist.sys.smartpower.limit.max.refresh.rate \
    persist.sys.smartpower.limit.normal.max.refresh.rate.support \
    persist.sys.smartpower.limit.normal.max.refresh.rate.enable \
    vendor.display.enable_optimal_refresh_rate \
    vendor.display.enable_idle_content_fps_hint ; do
    $RP -d -p "$p" 2>/dev/null
done
echo "已删除覆写的 persist 属性"

# 复位触控节点
[ -f /proc/HighReportRate ] && echo 0 > /proc/HighReportRate 2>/dev/null
[ -f /proc/game_edge ] && echo 0 > /proc/game_edge 2>/dev/null
[ -f /proc/report_threshold ] && echo 0 > /proc/report_threshold 2>/dev/null
[ -f /proc/gesture_control ] && echo 0 > /proc/gesture_control 2>/dev/null
echo "触控节点已复位"

# 清除日志
rm -f "$MODDIR/apply.log" "$MODDIR/refresh_monitor.log" 2>/dev/null
rm -f "$MODDIR/daemon.pid" 2>/dev/null
echo "运行时文件已清除"

echo "$(date): ===== 卸载清理完成 ====="