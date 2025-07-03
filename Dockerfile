# 企業知識庫系統 - Zeabur 輕量級部署 Dockerfile
FROM node:18-slim as frontend

WORKDIR /app

# 複製前端配置文件
COPY package*.json ./
COPY next.config.js ./
COPY tsconfig.json ./
COPY postcss.config.js ./
COPY tailwind.config.js ./

# 安裝依賴
RUN npm install --legacy-peer-deps \
    next@13.4.19 \
    react@18.2.0 \
    react-dom@18.2.0 \
    tailwindcss@latest \
    postcss@latest \
    autoprefixer@latest \
    && npm install --save-dev --legacy-peer-deps \
    @types/node@18.11.3 \
    @types/react@18.0.21 \
    @types/react-dom@18.0.6 \
    typescript@4.9.4 \
    tailwindcss-animate@latest

# 複製源代碼
COPY app ./app
COPY components ./components
COPY styles ./styles
COPY public ./public

# 構建前端
RUN NEXT_TELEMETRY_DISABLED=1 NODE_OPTIONS="--max-old-space-size=4096" npm run build

FROM python:3.11-slim

WORKDIR /app

# 系統依賴
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    supervisor \
    procps \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 環境變數
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    NODE_ENV=production \
    TORCH_HOME=/app/.cache/torch \
    HF_HOME=/app/.cache/huggingface \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000

# Python 依賴
COPY scripts/requirements-minimal.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 複製前端構建結果
COPY --from=frontend /app/.next ./.next
COPY --from=frontend /app/public ./public

# 複製其餘源文件
COPY . .

# 創建必要目錄
RUN mkdir -p /var/log/supervisor /var/log/nginx /var/run \
    user_documents user_indexes logs

# Nginx 配置
RUN echo 'user www-data;' > /etc/nginx/nginx.conf && \
    echo 'worker_processes auto;' >> /etc/nginx/nginx.conf && \
    echo 'pid /run/nginx.pid;' >> /etc/nginx/nginx.conf && \
    echo 'error_log /var/log/nginx/error.log warn;' >> /etc/nginx/nginx.conf && \
    echo 'events { worker_connections 1024; multi_accept on; }' >> /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '    default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '    access_log /var/log/nginx/access.log;' >> /etc/nginx/nginx.conf && \
    echo '    error_log /var/log/nginx/error.log;' >> /etc/nginx/nginx.conf && \
    echo '    sendfile on; tcp_nopush on; tcp_nodelay on;' >> /etc/nginx/nginx.conf && \
    echo '    keepalive_timeout 65;' >> /etc/nginx/nginx.conf && \
    echo '    gzip on;' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/conf.d/*.conf;' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/sites-enabled/*;' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

# Nginx 站點配置
RUN echo 'upstream nextjs_upstream { server 127.0.0.1:3000; }' > /etc/nginx/sites-available/default && \
    echo 'upstream fastapi_upstream { server 127.0.0.1:8000; }' >> /etc/nginx/sites-available/default && \
    echo 'server {' >> /etc/nginx/sites-available/default && \
    echo '    listen 80 default_server;' >> /etc/nginx/sites-available/default && \
    echo '    client_max_body_size 50M;' >> /etc/nginx/sites-available/default && \
    echo '    location / { proxy_pass http://nextjs_upstream; }' >> /etc/nginx/sites-available/default && \
    echo '    location /api/ { proxy_pass http://fastapi_upstream; }' >> /etc/nginx/sites-available/default && \
    echo '    location /auth/ { proxy_pass http://fastapi_upstream; }' >> /etc/nginx/sites-available/default && \
    echo '    location /_next/static/ { alias /app/.next/static/; }' >> /etc/nginx/sites-available/default && \
    echo '    location = /health { return 200 "OK"; }' >> /etc/nginx/sites-available/default && \
    echo '}' >> /etc/nginx/sites-available/default && \
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Supervisor 配置
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:fastapi]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=python scripts/auth_api_server.py' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=PYTHONUNBUFFERED="1",PYTHONPATH="/app"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:nextjs]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=npm run start' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=NODE_ENV="production",PORT="3000",NEXT_TELEMETRY_DISABLED="1"' >> /etc/supervisor/conf.d/supervisord.conf

# 啟動腳本
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo 'mkdir -p user_documents user_indexes logs .next/static' >> /app/start.sh && \
    echo 'exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf' >> /app/start.sh && \
    chmod +x /app/start.sh

# 健康檢查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80

CMD ["/app/start.sh"] 