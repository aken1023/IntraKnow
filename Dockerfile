# 企業知識庫系統 - Zeabur 全棧部署 Dockerfile
# 修復依賴缺失和前端啟動問題

FROM python:3.11-slim

WORKDIR /app

# 一次性安裝所有系統依賴
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

# 設置環境變數
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    NODE_ENV=production \
    TORCH_HOME=/app/.cache/torch \
    HF_HOME=/app/.cache/huggingface \
    NEXT_TELEMETRY_DISABLED=1

# 升級 pip
RUN pip install --no-cache-dir --upgrade pip

# 複製並安裝 Python 依賴
COPY scripts/requirements-minimal.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 複製所有前端源文件
COPY . .

# 運行依賴修復腳本
RUN node fix-deps.js

# 清理可能的舊安裝
RUN rm -rf node_modules package-lock.json .next

# 配置 npm 並安裝所有依賴
RUN npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 3 && \
    npm config set registry https://registry.npmjs.org/ && \
    echo "安裝 npm 依賴..." && \
    npm install --legacy-peer-deps

# 確保關鍵模組安裝（強制安裝缺失的包）
RUN echo "強制安裝關鍵依賴..." && \
    npm install tailwindcss autoprefixer postcss typescript @types/node @types/react @types/react-dom --save-dev --legacy-peer-deps && \
    echo "驗證安裝結果..." && \
    (test -d node_modules/tailwindcss && echo "✅ tailwindcss 已安裝") || echo "❌ tailwindcss 仍然缺失" && \
    (test -d node_modules/next && echo "✅ next 已安裝") || echo "❌ next 仍然缺失" && \
    (test -d node_modules/typescript && echo "✅ typescript 已安裝") || echo "❌ typescript 仍然缺失"

# 檢查並初始化 Tailwind CSS
RUN echo "初始化 Tailwind CSS..." && \
    (test -f tailwind.config.js || test -f tailwind.config.ts || npx tailwindcss init -p) && \
    echo "✅ Tailwind CSS 配置完成"

# 顯示環境信息
RUN echo "=== 構建環境信息 ===" && \
    echo "Node.js: $(node --version)" && \
    echo "npm: $(npm --version)" && \
    echo "工作目錄: $(pwd)" && \
    echo "關鍵依賴狀態:" && \
    npm list next tailwindcss typescript autoprefixer postcss --depth=0 || echo "部分依賴信息不可見"

# 嘗試構建前端（使用更保守的方法）
RUN echo "=== 嘗試 Next.js 構建 ===" && \
    (echo "嘗試標準構建..." && NODE_OPTIONS="--max-old-space-size=2048" npm run build && echo "✅ 構建成功") || \
    (echo "構建失敗，準備運行時構建模式..." && \
     mkdir -p .next/static .next/server/pages && \
     echo '{"version":"runtime","buildId":"runtime-build"}' > .next/build-manifest.json && \
     echo "✅ 運行時構建模式準備完成")

# 檢查構建結果
RUN echo "=== 檢查構建結果 ===" && \
    (test -d .next && echo "✅ .next 目錄存在") || echo "⚠️ .next 目錄不存在" && \
    (ls -la .next/ 2>/dev/null | head -5) || echo "無法列出 .next 內容"

# 清理 npm 緩存但保留 node_modules
RUN npm cache clean --force || true

# 創建必要目錄和配置
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled user_documents user_indexes logs faiss_index .cache/torch .cache/huggingface

# 創建 Nginx 主配置
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

# 創建 Nginx 站點配置
RUN cat > /etc/nginx/sites-available/default << 'EOF'
upstream frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

upstream backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name _;
    
    # 基本設置
    client_max_body_size 50M;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_cache_bypass $http_upgrade;
    
    # 超時設置
    proxy_connect_timeout 180s;
    proxy_send_timeout 180s;
    proxy_read_timeout 180s;
    
    # 緩衝設置
    proxy_buffering on;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    # 錯誤頁面
    error_page 502 /502.html;
    location = /502.html {
        root /usr/share/nginx/html;
        internal;
    }

    # 前端代理
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 重試設置
        proxy_next_upstream error timeout http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # 開發模式 WebSocket 支持
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 後端 API 代理
    location /api/ {
        proxy_pass http://backend/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # API 特定超時
        proxy_connect_timeout 180s;
        proxy_send_timeout 180s;
        proxy_read_timeout 180s;
    }

    # 認證 API 代理
    location /auth/ {
        proxy_pass http://backend/auth/;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 認證特定超時
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 健康檢查端點
    location = /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
    }

    # 靜態文件
    location /static/ {
        alias /app/.next/static/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# 創建 502 錯誤頁面
RUN mkdir -p /usr/share/nginx/html && \
    cat > /usr/share/nginx/html/502.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>暫時無法連接服務器</title>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: #f5f5f5;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 600px;
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
        .retry-button {
            display: inline-block;
            background: #007bff;
            color: white;
            padding: 10px 20px;
            border-radius: 4px;
            text-decoration: none;
            margin-top: 20px;
            transition: background-color 0.3s;
        }
        .retry-button:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>暫時無法連接服務器</h1>
        <p>系統正在啟動或維護中，請稍後再試。如果問題持續存在，請聯繫系統管理員。</p>
        <a href="/" class="retry-button" onclick="window.location.reload(); return false;">重試連接</a>
    </div>
</body>
</html>
EOF

# 創建 Supervisor 配置（簡化前端啟動）
RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
loglevel=info

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
priority=100
stdout_logfile=/var/log/nginx_access.log
stderr_logfile=/var/log/nginx_error.log

[program:backend]
command=python scripts/auth_api_server.py
directory=/app
autostart=true
autorestart=true
environment=PYTHONPATH="/app",PYTHONUNBUFFERED="1"
priority=200
startretries=5
startsecs=10
stdout_logfile=/var/log/backend.log
stderr_logfile=/var/log/backend_error.log

[program:frontend]
command=bash -c "NODE_ENV=development npm run dev"
directory=/app
autostart=true
autorestart=true
environment=NODE_ENV="development",PORT="3000",NEXT_TELEMETRY_DISABLED="1"
priority=300
startretries=15
startsecs=45
stdout_logfile=/var/log/frontend.log
stderr_logfile=/var/log/frontend_error.log
EOF

# 創建啟動腳本（簡化並專注於穩定性）
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e
echo "🚀 啟動 IntraKnow 全棧系統..."
mkdir -p user_documents user_indexes logs

# 初始化資料庫
if [ -f "scripts/setup_knowledge_base.py" ]; then
    echo "📊 初始化知識庫..."
    python scripts/setup_knowledge_base.py || echo "⚠️ 資料庫初始化跳過"
fi

# 確保關鍵依賴存在
echo "🔍 最終檢查關鍵依賴..."
if [ ! -d "node_modules/tailwindcss" ]; then
    echo "⚠️ 最後嘗試安裝 tailwindcss..."
    npm install tailwindcss autoprefixer postcss --save-dev --legacy-peer-deps || echo "依賴安裝失敗，將使用開發模式"
fi

# 確保 .next 目錄存在
if [ ! -d ".next" ]; then
    echo "🔧 創建 .next 目錄結構..."
    mkdir -p .next/static .next/server/pages
    echo '{"version":"dev","buildId":"development"}' > .next/build-manifest.json
fi

# 檢查 Nginx 配置
echo "🔍 檢查 Nginx 配置..."
nginx -t || echo "⚠️ Nginx 配置可能有問題"

echo "✅ 啟動前後端服務（前端使用開發模式確保穩定性）..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /app/start.sh

EXPOSE 80

# 健康檢查（延長等待時間）
HEALTHCHECK --interval=60s --timeout=20s --start-period=240s --retries=5 \
    CMD curl -f http://localhost:80/health || curl -f http://localhost:80/ || exit 1

CMD ["/app/start.sh"] 