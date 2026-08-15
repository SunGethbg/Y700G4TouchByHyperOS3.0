#!/system/bin/sh
# 输出 /Hyw.log 内容（纯文本）
echo "Content-type: text/plain; charset=utf-8"
echo ""

LOG_FILE="/Hyw.log"
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE" 2>/dev/null
else
    echo "日志文件不存在: $LOG_FILE"
fi