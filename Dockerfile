# Fleet image — one image for every terrain.
# xray (VLESS+WS / VLESS+REALITY) + shadowsocks-rust (SS).
# Build: docker build -t fleet:latest .
# Run:   docker run -e PROTOCOL=vless-ws -e UUID=... -e WS_PATH=... -e PORT=8000 -p 8000:8000 fleet:latest
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*
# xray-core (pinned; bump XRAY_VERSION to upgrade)
ARG XRAY_VERSION=25.12.8
RUN curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip" \
 && unzip -o /tmp/xray.zip -d /tmp/xray \
 && install -m 0755 /tmp/xray/xray /app/xray \
 && rm -rf /tmp/xray /tmp/xray.zip
# shadowsocks-rust (pinned; bump SS_VERSION to upgrade)
ARG SS_VERSION=1.24.0
RUN curl -fsSL -o /tmp/ss.tar.xz "https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${SS_VERSION}/shadowsocks-v${SS_VERSION}.x86_64-unknown-linux-gnu.tar.xz" \
 && tar -xJf /tmp/ss.tar.xz -C /tmp \
 && install -m 0755 /tmp/ssserver /app/ssserver \
 && rm -rf /tmp/ssserver /tmp/ss.tar.xz
COPY entrypoint.sh /app/entrypoint.sh
COPY xray-vless-ws.json.template /app/xray-vless-ws.json.template
COPY xray-vless-reality.json.template /app/xray-vless-reality.json.template
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
