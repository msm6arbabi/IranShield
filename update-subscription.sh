#!/bin/bash
# ============================================
# 🛡️ IranShield — بروزرسانی ساب‌لینک
# ============================================
# هر بار اجرا آخرین کانفیگ‌ها رو دانلود می‌کنه
# و sing-box رو ری‌استارت می‌کنه
# ============================================

set -e

DIR="$HOME/.iranshield"
CONFIG="$DIR/config.json"
BACKUP="$DIR/config.json.bak"
PYTHON_SCRIPT="$DIR/fetch-subscription.py"
LOG="$DIR/update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

# Download the fetch script if not exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log "📥 دانلود اسکریپت fetch-subscription.py..."
    mkdir -p "$DIR"
    curl -sL "https://raw.githubusercontent.com/msm6arbabi/IranShield/main/fetch-subscription.py" -o "$PYTHON_SCRIPT"
    chmod +x "$PYTHON_SCRIPT"
fi

# Backup current config
if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$BACKUP"
fi

log "🔄 شروع بروزرسانی..."

# Run the fetch script
python3 "$PYTHON_SCRIPT" 2>&1 | tee -a "$LOG"

if [ $? -eq 0 ] && [ -f "$CONFIG" ]; then
    # Validate new config
    if ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true ENABLE_DEPRECATED_TUN_ADDRESS_X=true sing-box check -c "$CONFIG" 2>&1 | grep -q "FATAL"; then
        log "❌ کانفیگ جدید نامعتبره - بازگشت به نسخه قبل"
        cp "$BACKUP" "$CONFIG"
        exit 1
    fi

    log "✅ بروزرسانی موفق!"

    # Restart sing-box if running
    PID_FILE="$DIR/sing-box.pid"
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log "🔄 ری‌استارت sing-box..."
        kill $(cat "$PID_FILE") 2>/dev/null
        rm -f "$PID_FILE"
        sleep 2
        cd "$DIR"
        nohup sing-box run -c "$CONFIG" > "$DIR/sing-box.log" 2>&1 &
        echo $! > "$PID_FILE"
        log "✅ sing-box ری‌استارت شد (PID: $(cat $PID_FILE))"
    fi
else
    log "❌ خطا در بروزرسانی"
    if [ -f "$BACKUP" ]; then
        cp "$BACKUP" "$CONFIG"
        log "↩️  بازگشت به نسخه قبل"
    fi
    exit 1
fi
