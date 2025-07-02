# 企業知識庫系統 - Zeabur 全棧部署 Dockerfile
# 修復 tailwindcss 缺失問題的版本

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

# 配置 npm 並安裝所有依賴（包含 dev dependencies）
RUN npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 3 && \
    npm config set registry https://registry.npmjs.org/ && \
    echo "安裝 npm 依賴..." && \
    npm install --legacy-peer-deps

# 檢查關鍵模組是否存在
RUN echo "檢查關鍵模組..." && \
    test -d node_modules/tailwindcss || (echo "錯誤: tailwindcss 未安裝" && npm list tailwindcss) && \
    test -d node_modules/next || (echo "錯誤: next 未安裝" && npm list next) && \
    test -d node_modules/typescript || (echo "錯誤: typescript 未安裝" && npm list typescript)

# 檢查並創建必要的配置文件
RUN echo "檢查配置文件..." && \
    test -f tailwind.config.js || test -f tailwind.config.ts || (echo "警告: tailwind 配置文件缺失") && \
    test -f next.config.mjs || test -f next.config.js || (echo "警告: next 配置文件缺失") && \
    test -f tsconfig.json || (echo "警告: TypeScript 配置文件缺失")

# 顯示環境信息
RUN echo "=== 構建環境信息 ===" && \
    echo "Node.js: $(node --version)" && \
    echo "npm: $(npm --version)" && \
    echo "工作目錄: $(pwd)" && \
    echo "主要依賴版本:" && \
    npm list --depth=0 next tailwindcss typescript 2>/dev/null || echo "無法顯示部分依賴版本"

# 構建前端（分步進行，便於調試）
RUN echo "=== 開始 Next.js 構建 ===" && \
    NODE_OPTIONS="--max-old-space-size=2048" npm run build

# 檢查構建結果
RUN echo "=== 檢查構建結果 ===" && \
    test -d .next && echo "✅ .next 目錄已創建" || (echo "❌ 構建失敗" && exit 1) && \
    ls -la .next/ || echo "無法列出 .next 內容"

# 安裝生產依賴（保留構建結果）
RUN echo "=== 切換到生產依賴 ===" && \
    rm -rf node_modules && \
    npm ci --only=production --silent || npm install --only=production --legacy-peer-deps && \
    npm cache clean --force

# 創建必要目錄和配置
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled user_documents user_indexes logs faiss_index .cache/torch .cache/huggingface

# 創建 Nginx 配置
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    client_max_body_size 50M;\n\
    location / {\n\
        proxy_pass http://localhost:3000;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_connect_timeout 60s;\n\
        proxy_send_timeout 60s;\n\
        proxy_read_timeout 60s;\n\
    }\n\
    location /api/ {\n\
        proxy_pass http://localhost:8000/api/;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
    location /auth/ {\n\
        proxy_pass http://localhost:8000/auth/;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
    location /health {\n\
        proxy_pass http://localhost:8000/health;\n\
        proxy_set_header Host $host;\n\
    }\n\
}' > /etc/nginx/sites-available/default

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# 創建 Supervisor 配置
RUN printf '[supervisord]\n\
nodaemon=true\n\
user=root\n\
loglevel=info\n\
\n\
[program:nginx]\n\
command=nginx -g "daemon off;"\n\
autostart=true\n\
autorestart=true\n\
priority=100\n\
\n\
[program:backend]\n\
command=python scripts/auth_api_server.py\n\
directory=/app\n\
autostart=true\n\
autorestart=true\n\
environment=PYTHONPATH="/app",PYTHONUNBUFFERED="1"\n\
priority=200\n\
startretries=5\n\
startsecs=10\n\
\n\
[program:frontend]\n\
command=npm start\n\
directory=/app\n\
autostart=true\n\
autorestart=true\n\
environment=NODE_ENV="production",PORT="3000"\n\
priority=300\n\
startretries=5\n\
startsecs=15' > /etc/supervisor/conf.d/supervisord.conf

# 創建啟動腳本
RUN printf '#!/bin/bash\n\
set -e\n\
echo "🚀 啟動 IntraKnow 全棧系統..."\n\
mkdir -p user_documents user_indexes logs\n\
\n\
# 初始化資料庫\n\
if [ -f "scripts/setup_knowledge_base.py" ]; then\n\
    echo "📊 初始化知識庫..."\n\
    python scripts/setup_knowledge_base.py || echo "⚠️ 資料庫初始化跳過"\n\
fi\n\
\n\
echo "✅ 啟動前後端服務..."\n\
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' > /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 80

# 健康檢查
HEALTHCHECK --interval=60s --timeout=15s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:80/health || curl -f http://localhost:80/ || exit 1

CMD ["/app/start.sh"] 