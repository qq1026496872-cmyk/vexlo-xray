#!/bin/sh
# Fleet entrypoint — one image, one script, one parameter set.
# Protocol is chosen by terrain via PROTOCOL:
#   ss            bare metal / VPS with public ports (simple, direct)
#   vless-ws      PaaS with only a web entry (VLESS+WS, behind the platform TLS)
#   vless-reality direct scenarios needing strong camouflage (REALITY)
set -e

PROTOCOL="${PROTOCOL:-vless-ws}"
PORT="${PORT:-8000}"

# Common identity (single parameter set)
UUID="${UUID:-}"
PASSWORD="${PASSWORD:-}"
WS_PATH="${WS_PATH:-/fleet-ws}"

case "$PROTOCOL" in
  ss)
    : "${PASSWORD:?PASSWORD env var is required for ss}"
    METHOD="${METHOD:-aes-256-gcm}"
    cat > /app/ss.json <<EOF
{
  "server": "0.0.0.0",
  "server_port": ${PORT},
  "password": "${PASSWORD}",
  "method": "${METHOD}",
  "mode": "tcp_and_udp",
  "timeout": 300
}
EOF
    echo "fleet: starting shadowsocks (${METHOD}) on 0.0.0.0:${PORT}"
    exec /app/ssserver -c /app/ss.json
    ;;
  vless-ws)
    : "${UUID:?UUID env var is required for vless-ws}"
    sed -e "s|__PORT__|${PORT}|g" \
        -e "s|__UUID__|${UUID}|g" \
        -e "s|__WS_PATH__|${WS_PATH}|g" \
        /app/xray-vless-ws.json.template > /app/config.json
    echo "fleet: starting xray vless-ws on 0.0.0.0:${PORT} path ${WS_PATH}"
    exec /app/xray run -c /app/config.json
    ;;
  vless-reality)
    : "${UUID:?UUID env var is required for vless-reality}"
    : "${PRIVATE_KEY:?PRIVATE_KEY env var is required for vless-reality}"
    : "${SHORT_ID:?SHORT_ID env var is required for vless-reality}"
    SNI="${SNI:-www.microsoft.com}"
    DEST="${DEST:-www.microsoft.com:443}"
    sed -e "s|__PORT__|${PORT}|g" \
        -e "s|__UUID__|${UUID}|g" \
        -e "s|__PRIVATE_KEY__|${PRIVATE_KEY}|g" \
        -e "s|__SHORT_ID__|${SHORT_ID}|g" \
        -e "s|__SNI__|${SNI}|g" \
        -e "s|__DEST__|${DEST}|g" \
        /app/xray-vless-reality.json.template > /app/config.json
    echo "fleet: starting xray vless-reality on 0.0.0.0:${PORT} sni ${SNI}"
    exec /app/xray run -c /app/config.json
    ;;
  *)
    echo "fleet: unknown PROTOCOL '${PROTOCOL}' (want ss | vless-ws | vless-reality)" >&2
    exit 2
    ;;
esac
