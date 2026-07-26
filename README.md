# 🛡️ IranShield VPN

فیلترشکن اختصاصی مخصوص اینترنت ایران — ترکیبی از بهترین ۵۰+ پروژه متن‌باز

## ⚡ نصب سریع

```bash
# در Termux:
pkg install python curl
bash <(curl -sL https://raw.githubusercontent.com/msm6arbabi/IranShield/main/setup.sh)
```

## 📱 دستورات

| دستور | توضیح |
|--------|--------|
| `iranshield start` | شروع اتصال |
| `iranshield stop` | توقف اتصال |
| `iranshield restart` | ری‌استارت |
| `iranshield status` | وضعیت + تعداد نودها |
| `iranshield update` | بروزرسانی ساب‌لینک |
| `iranshield log` | نمایش لاگ |

## 🌐 رابط وب

```
http://127.0.0.1:9090/ui
```

## 📊 ویژگی‌ها

- ✅ **۲۴۱+ نود** از ۲۰+ کشور
- ✅ **VLESS+Reality** — نامرئی در برابر DPI
- ✅ **Hysteria2** — UDP-based، دور زدن TCP DPI
- ✅ **Trojan** — پروتکل محبوب
- ✅ **Shadowsocks** — سبک و سریع
- ✅ **Auto-select** — انتخاب خودکار بهترین نود
- ✅ **Split routing** — دامنه‌های .ir مستقیم
- ✅ **TUN mode** — روت کامل سیستم
- ✅ **بروزرسانی خودکار** — ساب‌لینک همیشه بروز

## 🔄 بروزرسانی

```bash
iranshield update
```

## 📁 ساختار

```
~/.iranshield/
├── config.json              # کانفیگ sing-box
├── fetch-subscription.py    # دانلود ساب‌لینک
├── update-subscription.sh   # بروزرسانی
├── iranshield.sh            # مدیریت
└── sing-box.log             # لاگ
```

## 🙏 credits

- [WhiteDNS](https://github.com/WhiteDNS) — ساب‌لینک
- [sing-box](https://github.com/SagerNet/sing-box) — هسته پروتکل
- [Xray-core](https://github.com/XTLS/Xray-core) — VLESS+Reality
- [EasySNI](https://github.com/macan-dev/EasySNI) — تکنیک‌های ضد DPI
- [mhrv-rs](https://github.com/therealaleph/MasterHttpRelayVPN-RUST) — Google Relay

---
*ساخته شده برای اینترنت ایران 🇮🇷*
