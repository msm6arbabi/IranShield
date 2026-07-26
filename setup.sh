#!/bin/bash
# ============================================
# 🛡️ IranShield VPN — نصب سریع در Termux
# ============================================
# اجرا: bash <(curl -sL https://raw.githubusercontent.com/msm6arbabi/IranShield/main/setup.sh)
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO="msm6arbabi/IranShield"
BASE="https://raw.githubusercontent.com/$REPO/main"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════╗"
echo "║       🛡️  IranShield VPN  🛡️        ║"
echo "║    فیلترشکن اختصاصی اینترنت ایران    ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# Check Termux
if [ -z "$TERMUX_VERSION" ] && [ ! -d "/data/data/com.termux" ]; then
    echo "❌ لطفاً در Termux اجرا کنید"
    exit 1
fi
echo -e "${GREEN}✅ Termux OK${NC}"

# Install dependencies
echo -e "${YELLOW}📦 نصب پکیج‌ها...${NC}"
pkg update -y
pkg install -y python curl wget

# Create directory
mkdir -p ~/.iranshield
cd ~/.iranshield

# Install sing-box
echo -e "${YELLOW}📦 نصب sing-box...${NC}"
if command -v sing-box &>/dev/null; then
    echo -e "${GREEN}✅ sing-box از قبل نصب است${NC}"
else
    pkg install -y sing-box 2>/dev/null || {
        echo "دانلود sing-box..."
        ARCH=$(uname -m)
        case $ARCH in
            aarch64) SBA="arm64" ;;
            armv7l)  SBA="armv7" ;;
            *)       echo "❌ معماری پشتیبانی نشده"; exit 1 ;;
        esac
        wget -q -O sb.apk "https://github.com/SagerNet/sing-box/releases/download/v1.12.4/sing-box-1.12.4-android-${SBA}.apk"
        unzip -o sb.apk -d sb 2>/dev/null
        cp sb/lib/*/libclash.so sing-box 2>/dev/null || cp sb/lib/*/libbox.so sing-box 2>/dev/null
        chmod +x sing-box
        echo 'export PATH="$HOME/.iranshield:$PATH"' >> ~/.bashrc
    }
fi

# Download scripts
echo -e "${YELLOW}📥 دانلود اسکریپت‌ها...${NC}"
curl -sL "$BASE/iranshield.sh" -o iranshield.sh && chmod +x iranshield.sh
curl -sL "$BASE/fetch-subscription.py" -o fetch-subscription.py && chmod +x fetch-subscription.py
curl -sL "$BASE/update-subscription.sh" -o update-subscription.sh && chmod +x update-subscription.sh

# Create symlink
ln -sf ~/.iranshield/iranshield.sh ~/iranshield
echo 'export PATH="$HOME/.iranshield:$PATH"' >> ~/.bashrc

# Initial subscription fetch
echo -e "${YELLOW}📥 دانلود اولیه ساب‌لینک...${NC}"
python3 fetch-subscription.py

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ IranShield نصب شد!            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}دستورات:${NC}"
echo "  iranshield start      — شروع اتصال"
echo "  iranshield stop       — توقف اتصال"
echo "  iranshield restart    — ری‌استارت"
echo "  iranshield status     — وضعیت + نودها"
echo "  iranshield update     — بروزرسانی ساب‌لینک"
echo "  iranshield log        — لاگ"
echo ""
echo -e "${BLUE}🌐 رابط وب:${NC} http://127.0.0.1:9090/ui"
echo ""
echo -e "${YELLOW}برای شروع: iranshield start${NC}"
echo ""
echo -e "${BLUE}برای بروزرسانی خودکار (هر ۶ ساعت):${NC}"
echo "  iranshield update"
