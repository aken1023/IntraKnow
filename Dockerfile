# 企業知識庫系統 - Zeabur 全棧部署 Dockerfile
# 支持前後端整合部署

# 第一階段：構建前端
FROM node:18-slim as frontend-builder

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
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

# 創建配置文件
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /app/start.sh

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

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