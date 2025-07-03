# 企業知識庫系統 - Zeabur 全棧部署 Dockerfile
FROM python:3.11-slim

WORKDIR /app

# 系統依賴
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    nginx \
    supervisor \
    --no-install-recommends \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 環境變數
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    NODE_ENV=production \
    TORCH_HOME=/app/.cache/torch \
    HF_HOME=/app/.cache/huggingface \
    NEXT_TELEMETRY_DISABLED=1

# 升級 pip
RUN pip install --no-cache-dir --upgrade pip

# Python 依賴
COPY scripts/requirements-minimal.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 複製 package.json 和 package-lock.json（如果存在）
COPY package*.json ./
COPY next.config.js ./
COPY tsconfig.json ./
COPY postcss.config.js ./
COPY tailwind.config.js ./

# 安裝 npm 依賴
RUN npm install --legacy-peer-deps \
    next@13.4.19 \
    react@18.2.0 \
    react-dom@18.2.0 \
    tailwindcss@latest \
    postcss@latest \
    autoprefixer@latest \
    typescript@latest \
    @types/node@latest \
    @types/react@latest \
    @types/react-dom@latest

# 複製其餘源文件
COPY . .

# 創建必要目錄
RUN mkdir -p /var/log/supervisor /var/log/nginx /var/run \
    user_documents user_indexes logs .next/static

# 構建前端
RUN echo "開始構建前端..." && \
    NODE_OPTIONS="--max-old-space-size=2048" npm run build || \
    (echo "標準構建失敗，切換到開發模式..." && \
    NODE_ENV=development npm run dev)

# Nginx 配置
RUN cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Nginx 站點配置
RUN cat > /etc/nginx/sites-available/default << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream nextjs_upstream {
    server localhost:3000;
    keepalive 32;
}

upstream fastapi_upstream {
    server localhost:8000;
    keepalive 32;
}

server {
    listen ${PORT} default_server;
    server_name _;

    # 基本設置
    client_max_body_size ${MAX_FILE_SIZE};
    proxy_http_version 1.1;
    
    # 通用代理設置
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # WebSocket 支持
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    # 前端路由
    location / {
        proxy_pass http://nextjs_upstream;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        proxy_read_timeout 300s;
    }

    # API 路由
    location /api/ {
        proxy_pass http://fastapi_upstream;
        proxy_read_timeout 300s;
    }

    # 認證路由
    location /auth/ {
        proxy_pass http://fastapi_upstream;
        proxy_read_timeout 60s;
    }

    # 靜態文件
    location /_next/static/ {
        alias /app/.next/static/;
        expires 365d;
        access_log off;
    }

    # 健康檢查
    location /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Supervisor 配置
RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/var/log/nginx/access.log
stderr_logfile=/var/log/nginx/error.log

[program:fastapi]
command=python scripts/auth_api_server.py
directory=/app
autostart=true
autorestart=true
stdout_logfile=/var/log/fastapi.log
stderr_logfile=/var/log/fastapi_error.log

[program:nextjs]
command=npm run dev
directory=/app
autostart=true
autorestart=true
environment=NODE_ENV="development",PORT="3000"
stdout_logfile=/var/log/nextjs.log
stderr_logfile=/var/log/nextjs_error.log
EOF

# 啟動腳本
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e

echo "初始化環境..."
mkdir -p user_documents user_indexes logs

# 替換環境變數
envsubst "\${PORT} \${MAX_FILE_SIZE}" < /etc/nginx/sites-available/default > /etc/nginx/sites-available/default.tmp
mv /etc/nginx/sites-available/default.tmp /etc/nginx/sites-available/default

echo "啟動服務..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /app/start.sh

EXPOSE ${PORT}

CMD ["/app/start.sh"] 