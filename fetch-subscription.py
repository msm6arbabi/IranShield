#!/usr/bin/env python3
"""
IranShield — دانلود و تبدیل ساب‌لینک به کانفیگ sing-box
"""
import base64
import json
import re
import urllib.request
import urllib.parse
import sys
import os

SUB_URL = "https://raw.githubusercontent.com/iampedii/whitedns-sub/refs/heads/main/base64.txt"
CONFIG_PATH = os.path.expanduser("~/.iranshield/config.json")

print("📥 دانلود ساب‌لینک WhiteDNS...")
try:
    data = urllib.request.urlopen(SUB_URL, timeout=15).read()
    raw = base64.b64decode(data).decode("utf-8")
except Exception as e:
    print(f"❌ خطا در دانلود: {e}")
    sys.exit(1)

lines = [l.strip() for l in raw.strip().split("\n") if l.strip()]
print(f"✅ {len(lines)} کانفیگ دریافت شد")

outbounds = []
for i, line in enumerate(lines):
    proto = line.split(":")[0].split("/")[0]
    tag = f"sub-{i:03d}"

    try:
        # Extract server
        at_idx = line.index("@")
        port_query = line[at_idx+1:]
        if "?" in port_query:
            server_host, query = port_query.split("?", 1)
        else:
            server_host, query = port_query, ""
        server = server_host.split(":")[0]
        port = int(server_host.split(":")[1]) if ":" in server_host else 443

        params = dict(urllib.parse.parse_qsl(query))
        sni = params.get("sni", server)
        fp = params.get("fp", "chrome")

        if proto == "vless":
            ob = {
                "type": "vless", "tag": tag,
                "server": server, "server_port": port,
                "uuid": params.get("uuid", ""),
                "tls": {
                    "enabled": True, "server_name": sni,
                    "utls": {"enabled": True, "fingerprint": fp}
                }
            }
            if params.get("flow"):
                ob["flow"] = params["flow"]
            if params.get("security") == "reality" and params.get("pbk"):
                ob["tls"]["reality"] = {
                    "enabled": True,
                    "public_key": params["pbk"],
                    "short_id": params.get("sid", "")
                }
            outbounds.append(ob)

        elif proto == "trojan":
            outbounds.append({
                "type": "trojan", "tag": tag,
                "server": server, "server_port": port,
                "password": params.get("password", ""),
                "tls": {
                    "enabled": True, "server_name": sni,
                    "utls": {"enabled": True, "fingerprint": fp}
                }
            })

        elif proto == "ss":
            # ss://base64(method:password)@server:port
            b64_part = line.split("://")[1].split("@")[0]
            try:
                decoded = base64.b64decode(b64_part).decode()
                method, password = decoded.split(":", 1)
            except:
                method = params.get("method", "aes-128-gcm")
                password = params.get("password", "")
            outbounds.append({
                "type": "shadowsocks", "tag": tag,
                "server": server, "server_port": port,
                "method": method, "password": password
            })

        elif proto in ("hysteria2", "hy2"):
            outbounds.append({
                "type": "hysteria2", "tag": tag,
                "server": server, "server_port": port,
                "password": params.get("password", ""),
                "tls": {"enabled": True, "server_name": sni}
            })

        elif proto == "vmess":
            try:
                vmess_json = base64.b64decode(line.split("://")[1]).decode()
                vm = json.loads(vmess_json)
                outbounds.append({
                    "type": "vmess", "tag": tag,
                    "server": vm.get("add", server),
                    "server_port": int(vm.get("port", port)),
                    "uuid": vm.get("id", ""),
                    "alter_id": int(vm.get("aid", 0)),
                    "security": vm.get("scy", "auto"),
                    "tls": {
                        "enabled": vm.get("tls") == "tls",
                        "server_name": vm.get("sni", vm.get("host", "")),
                        "utls": {"enabled": True, "fingerprint": fp}
                    } if vm.get("tls") == "tls" else None
                })
            except:
                pass

        else:
            print(f"  ⚠️  رد شد: {proto}")
            continue

        print(f"  ✅ [{proto.upper()}] {tag} — {server}:{port}")

    except Exception as e:
        print(f"  ⚠️  خطا در خط {i}: {e}")
        continue

if not outbounds:
    print("❌ هیچ کانفیگی ساخته نشد")
    sys.exit(1)

# Build final config
config = {
    "log": {"level": "warning", "timestamp": True},
    "dns": {
        "servers": [
            {"tag": "google", "address": "https://8.8.8.8/dns-query", "detour": "proxy"},
            {"tag": "cf", "address": "https://1.1.1.1/dns-query", "detour": "proxy"},
            {"tag": "local", "address": "223.5.5.5", "detour": "direct-out"}
        ],
        "rules": [
            {"outbound": ["any"], "server": "local"},
            {"domain_suffix": [".ir"], "server": "local"}
        ],
        "strategy": "prefer_ipv4"
    },
    "inbounds": [
        {
            "type": "tun", "tag": "tun-in",
            "interface_name": "tun0",
            "address": ["172.19.0.1/30"],
            "auto_route": True, "strict_route": True,
            "stack": "system", "sniff": True,
            "sniff_override_destination": True
        },
        {
            "type": "mixed", "tag": "mixed-in",
            "listen_port": 2080, "listen": "127.0.0.1"
        }
    ],
    "outbounds": [
        {"type": "selector", "tag": "proxy",
         "outbounds": ["auto", "direct-out"], "default": "auto"},
        {"type": "urltest", "tag": "auto",
         "outbounds": [o["tag"] for o in outbounds],
         "url": "https://www.gstatic.com/generate_204",
         "interval": "5m", "tolerance": 50},
    ] + outbounds + [
        {"type": "direct", "tag": "direct-out"},
        {"type": "block", "tag": "block"},
        {"type": "dns", "tag": "dns-out"}
    ],
    "route": {
        "auto_detect_interface": True,
        "final": "proxy",
        "rules": [
            {"protocol": "dns", "outbound": "dns-out"},
            {"domain_suffix": [".ir"], "outbound": "direct-out"},
            {"ip_cidr": [
                "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8",
                "169.254.0.0/16", "172.16.0.0/12", "192.168.0.0/16",
                "198.18.0.0/15", "224.0.0.0/3", "fc00::/7", "fe80::/10"
            ], "outbound": "direct-out"}
        ]
    },
    "experimental": {
        "cache_file": {"enabled": True},
        "clash_api": {
            "external_controller": "127.0.0.1:9090",
            "external_ui": "ui",
            "external_ui_download_url": "https://github.com/MetaCubeX/metacubexd/releases/latest/download/metacubexd.zip",
            "external_ui_download_detour": "direct-out"
        }
    }
}

os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
with open(CONFIG_PATH, "w") as f:
    json.dump(config, f, indent=2)

print(f"\n✅ کانفیگ ذخیره شد: {CONFIG_PATH}")
print(f"📊 تعداد نودها: {len(outbounds)}")
print(f"📁 فایل: {CONFIG_PATH}")
