# 企業知識庫系統 - Zeabur 全棧部署 Dockerfile
# 支持前後端整合部署

# 第一階段：構建前端
FROM node:18-slim as frontend-builder

WORKDIR /app

# 複製前端相關文件
COPY package*.json ./
COPY next.config.mjs ./
COPY tsconfig.json ./
COPY tailwind.config.* ./
COPY postcss.config.* ./
COPY components.json ./

# 安裝前端依賴
RUN npm install --legacy-peer-deps

# 複製前端源代碼
COPY app/ ./app/
COPY components/ ./components/
COPY lib/ ./lib/
COPY hooks/ ./hooks/
COPY styles/ ./styles/
COPY public/ ./public/

# 構建前端
RUN npm run build

# 第二階段：運行時環境
FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    nginx \
    supervisor \
    netstat-nat \
    && rm -rf /var/lib/apt/lists/*

# 升級 pip 和安裝構建工具
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 設置環境變數
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV TORCH_HOME=/app/.cache/torch
ENV HF_HOME=/app/.cache/huggingface
ENV NODE_ENV=production

# 安裝 PyTorch (CPU 版本)
RUN pip install --no-cache-dir torch==2.1.0+cpu torchvision==0.16.0+cpu torchaudio==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu

# 複製 Python 依賴文件並安裝
COPY scripts/requirements-zeabur-fixed.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 複製後端代碼
COPY scripts/ ./scripts/
COPY documents/ ./documents/

# 從前端構建階段複製構建好的文件
COPY --from=frontend-builder /app/.next ./.next
COPY --from=frontend-builder /app/public ./public
COPY --from=frontend-builder /app/package*.json ./
COPY --from=frontend-builder /app/next.config.mjs ./

# 安裝 Node.js (用於運行 Next.js)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 安裝生產環境的 Node.js 依賴
RUN npm ci --only=production && npm cache clean --force

# 創建 Nginx 配置
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
RUN echo 'server {\n\
    listen 80;\n\
    server_name _;\n\
\n\
    # 設置客戶端請求大小限制\n\
    client_max_body_size 50M;\n\
\n\
    # 前端路由\n\
    location / {\n\
        proxy_pass http://localhost:3000;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Upgrade $http_upgrade;\n\
        proxy_set_header Connection '"'"'upgrade'"'"';\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_cache_bypass $http_upgrade;\n\
        proxy_read_timeout 86400;\n\
    }\n\
\n\
    # API 路由\n\
    location /api/ {\n\
        proxy_pass http://localhost:8000/api/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_read_timeout 300;\n\
    }\n\
\n\
    # 認證路由\n\
    location /auth/ {\n\
        proxy_pass http://localhost:8000/auth/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_read_timeout 300;\n\
    }\n\
\n\
    # 健康檢查路由\n\
    location /health {\n\
        proxy_pass http://localhost:8000/health;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
\n\
    # 靜態文件緩存\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {\n\
        proxy_pass http://localhost:3000;\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
}' > /etc/nginx/sites-available/default

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# 創建 Supervisor 配置
RUN echo '[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/var/log/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
\n\
[program:nginx]\n\
command=nginx -g "daemon off;"\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/nginx_error.log\n\
stdout_logfile=/var/log/nginx_access.log\n\
priority=100\n\
\n\
[program:backend]\n\
command=python scripts/auth_api_server.py\n\
directory=/app\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/backend_error.log\n\
stdout_logfile=/var/log/backend_access.log\n\
environment=PYTHONPATH="/app",PYTHONUNBUFFERED="1"\n\
priority=200\n\
startretries=3\n\
startsecs=10\n\
\n\
[program:frontend]\n\
command=npm start\n\
directory=/app\n\
autostart=true\n\
autorestart=true\n\
stderr_logfile=/var/log/frontend_error.log\n\
stdout_logfile=/var/log/frontend_access.log\n\
environment=NODE_ENV="production",PORT="3000"\n\
priority=300\n\
startretries=3\n\
startsecs=10' > /etc/supervisor/conf.d/supervisord.conf

# 創建啟動腳本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🚀 啟動 IntraKnow 企業知識庫系統"\n\
echo "📦 檢查環境..."\n\
\n\
# 檢查並創建必要目錄\n\
mkdir -p user_documents user_indexes logs\n\
\n\
# 檢查 Python 和 Node.js 是否可用\n\
echo "🐍 Python 版本: $(python --version)"\n\
echo "📦 Node.js 版本: $(node --version)"\n\
\n\
# 初始化數據庫（如果存在初始化腳本）\n\
if [ -f "scripts/setup_knowledge_base.py" ]; then\n\
    echo "🗄️ 初始化數據庫..."\n\
    python scripts/setup_knowledge_base.py\n\
fi\n\
\n\
echo "✅ 環境準備完成，啟動服務..."\n\
\n\
# 清理可能的舊進程\n\
pkill -f "nginx" || true\n\
pkill -f "python scripts/auth_api_server.py" || true\n\
pkill -f "npm start" || true\n\
\n\
# 等待一秒讓端口釋放\n\
sleep 1\n\
\n\
# 啟動 Supervisor\n\
echo "🔄 啟動 Supervisor..."\n\
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' > /app/start.sh

# 創建環境配置文件
RUN echo "EMBEDDING_MODEL=BAAI/bge-base-zh" > .env && \
    echo "MODEL_NAME=deepseek-chat" >> .env && \
    echo "PYTHONPATH=/app" >> .env && \
    echo "PYTHONUNBUFFERED=1" >> .env && \
    echo "NODE_ENV=production" >> .env && \
    echo "NEXT_PUBLIC_API_URL=/api" >> .env

# 創建必要目錄
RUN mkdir -p user_documents user_indexes logs faiss_index .cache/torch .cache/huggingface

# 設置權限
RUN chmod -R 755 /app && chmod +x /app/start.sh

# 使用動態端口
EXPOSE 80

# 健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:80/api/health || exit 1

# 啟動應用
CMD ["/app/start.sh"] 