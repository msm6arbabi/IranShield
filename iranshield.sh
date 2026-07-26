#!/bin/bash
# ============================================
# 🛡️ IranShield VPN — مدیریت اتصال
# ============================================

DIR="$HOME/.iranshield"
CONFIG="$DIR/config.json"
PID="$DIR/sing-box.pid"
LOG="$DIR/sing-box.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

start() {
    if [ -f "$PID" ] && kill -0 $(cat "$PID") 2>/dev/null; then
        echo -e "${GREEN}✅ IranShield در حال اجراست (PID: $(cat $PID))${NC}"
        return 0
    fi

    # Auto-update subscription if config is missing or empty
    if [ ! -f "$CONFIG" ] || [ ! -s "$CONFIG" ]; then
        echo -e "${YELLOW}📥 دانلود اولیه ساب‌لینک...${NC}"
        bash "$DIR/update-subscription.sh"
    fi

    if [ ! -f "$CONFIG" ]; then
        echo -e "${RED}❌ کانفیگ یافت نشد — اجرا: iranshield update${NC}"
        return 1
    fi

    echo -e "${YELLOW}🚀 راه‌اندازی IranShield...${NC}"
    cd "$DIR"

    env ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true ENABLE_DEPRECATED_TUN_ADDRESS_X=true \
        nohup sing-box run -c "$CONFIG" > "$LOG" 2>&1 &
    echo $! > "$PID"
    sleep 3

    if kill -0 $(cat "$PID") 2>/dev/null; then
        echo -e "${GREEN}✅ IranShield متصل شد! (PID: $(cat $PID))${NC}"
        echo ""
        echo "🌐 رابط وب: http://127.0.0.1:9090/ui"
        echo "📊 لاگ: iranshield log"
    else
        echo -e "${RED}❌ خطا در اتصال — لاگ: iranshield log${NC}"
    fi
}

stop() {
    if [ -f "$PID" ] && kill -0 $(cat "$PID") 2>/dev/null; then
        kill $(cat "$PID") 2>/dev/null
        rm -f "$PID"
        echo -e "${YELLOW}🛑 IranShield متوقف شد${NC}"
    else
        echo -e "${YELLOW}⚠️  IranShield اجرا نیست${NC}"
    fi
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f "$PID" ] && kill -0 $(cat "$PID") 2>/dev/null; then
        echo -e "${GREEN}✅ IranShield در حال اجراست (PID: $(cat $PID))${NC}"
        # Count nodes from config
        if [ -f "$CONFIG" ]; then
            NODES=$(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
types = {}
for o in c.get('outbounds',[]):
    t = o.get('type','')
    if t not in ('selector','urltest','direct','block','dns'):
        types[t] = types.get(t,0) + 1
for t,cnt in sorted(types.items()):
    print(f'  {t}: {cnt}')
print(f'  مجموع: {sum(types.values())}')
" 2>/dev/null)
            echo ""
            echo "📊 نودهای موجود:"
            echo "$NODES"
        fi
    else
        echo -e "${RED}❌ IranShield متوقف است${NC}"
    fi
}

update() {
    echo -e "${YELLOW}🔄 بروزرسانی ساب‌لینک...${NC}"
    bash "$DIR/update-subscription.sh"
}

log_view() {
    tail -f "$LOG" 2>/dev/null || echo -e "${RED}لاگ وجود ندارد${NC}"
}

config_view() {
    if [ -f "$CONFIG" ]; then
        echo "📁 کانفیگ: $CONFIG"
        echo "📊 حجم: $(du -h "$CONFIG" | cut -f1)"
        echo "📅 آخرین بروزرسانی: $(stat -c '%y' "$CONFIG" 2>/dev/null || echo 'نامشخص')"
    fi
}

case "$1" in
    start)    start ;;
    stop)     stop ;;
    restart)  restart ;;
    status)   status ;;
    update)   update ;;
    log)      log_view ;;
    config)   config_view ;;
    *)
        echo "🛡️  IranShield VPN — مدیریت"
        echo ""
        echo "دستورات:"
        echo "  iranshield start      — شروع اتصال"
        echo "  iranshield stop       — توقف اتصال"
        echo "  iranshield restart    — ری‌استارت"
        echo "  iranshield status     — وضعیت + تعداد نودها"
        echo "  iranshield update     — بروزرسانی ساب‌لینک"
        echo "  iranshield log        — نمایش لاگ"
        echo "  iranshield config     — اطلاعات کانفیگ"
        echo ""
        echo "🌐 رابط وب: http://127.0.0.1:9090/ui"
        ;;
esac
