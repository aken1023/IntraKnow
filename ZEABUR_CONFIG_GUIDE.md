# 🚀 Zeabur 部署配置指南

## 📋 必要的環境變數設定

在 Zeabur 控制台的「環境變數」頁面中，添加以下變數：

### 基本環境設定
```bash
# 運行環境
NODE_ENV=production
PYTHONUNBUFFERED=1
PYTHONPATH=/app

# 前端配置
NEXT_PUBLIC_API_URL=/api
PORT=3000
```

### AI 模型配置
```bash
# 嵌入模型（推薦使用輕量級模型）
EMBEDDING_MODEL=BAAI/bge-base-zh-v1.5

# 語言模型（可選，如果使用外部 API）
MODEL_NAME=deepseek-chat
# OPENAI_API_KEY=your_openai_key_here  # 如果使用 OpenAI
# DEEPSEEK_API_KEY=your_deepseek_key_here  # 如果使用 DeepSeek
```

### 系統配置
```bash
# 緩存目錄
TORCH_HOME=/app/.cache/torch
HF_HOME=/app/.cache/huggingface

# 數據庫設定（使用 SQLite）
DATABASE_URL=sqlite:///app/knowledge_base.db

# 文件上傳限制
MAX_FILE_SIZE=50MB
MAX_FILES_PER_USER=100
```

### 安全設定（重要）
```bash
# JWT 密鑰（請生成一個隨機的強密鑰）
JWT_SECRET_KEY=your_very_secure_random_key_here_change_this

# 會話密鑰
SESSION_SECRET=another_secure_random_key_here

# CORS 設定
ALLOWED_ORIGINS=https://your-zeabur-domain.zeabur.app
```

## 🔧 端口和網絡設定

### 端口配置
在 Zeabur 控制台「網絡」設定中：

1. **容器端口**：`80`
2. **協議**：`HTTP`
3. **路徑**：`/`（根路徑）
4. **自動 HTTPS**：啟用（推薦）

### 域名設定
1. **自動域名**：Zeabur 會自動分配一個域名
2. **自定義域名**：如果有自己的域名，可以在「域名」頁面添加

## 📦 資源配置建議

### 記憶體和 CPU
```
記憶體：2GB（最小 1GB）
CPU：2 核心（最小 1 核心）
```

### 磁盤空間
```
存儲：10GB（用於用戶文件和索引）
```

## 🔐 JWT 密鑰生成

你可以使用以下方法生成安全的密鑰：

### 方法一：線上生成器
訪問：https://randomkeygen.com/ 
選擇「CodeIgniter Encryption Keys」

### 方法二：Python 生成
```python
import secrets
print("JWT_SECRET_KEY=" + secrets.token_urlsafe(64))
print("SESSION_SECRET=" + secrets.token_urlsafe(64))
```

### 方法三：OpenSSL
```bash
openssl rand -base64 64
```

## 🗂️ 完整環境變數模板

複製以下模板到 Zeabur 環境變數設定：

```bash
# === 基本配置 ===
NODE_ENV=production
PYTHONUNBUFFERED=1
PYTHONPATH=/app
NEXT_PUBLIC_API_URL=/api
PORT=3000

# === AI 模型 ===
EMBEDDING_MODEL=BAAI/bge-base-zh-v1.5
MODEL_NAME=deepseek-chat

# === 系統路徑 ===
TORCH_HOME=/app/.cache/torch
HF_HOME=/app/.cache/huggingface
DATABASE_URL=sqlite:///app/knowledge_base.db

# === 安全設定 ===
JWT_SECRET_KEY=請_替換_為_你_的_安全_密鑰
SESSION_SECRET=請_替換_為_你_的_會話_密鑰
ALLOWED_ORIGINS=https://your-app-name.zeabur.app

# === 文件設定 ===
MAX_FILE_SIZE=50MB
MAX_FILES_PER_USER=100

# === 可選：外部 API ===
# OPENAI_API_KEY=your_openai_key_here
# DEEPSEEK_API_KEY=your_deepseek_key_here
```

## 🔍 部署後檢查

### 1. 健康檢查
訪問：`https://your-app.zeabur.app/api/health`
應該返回：`{"status": "healthy"}`

### 2. 前端檢查
訪問：`https://your-app.zeabur.app`
應該看到登入頁面

### 3. API 檢查
訪問：`https://your-app.zeabur.app/api`
應該看到 API 響應

## 🐛 常見問題排除

### 1. 應用無法啟動
- 檢查 `JWT_SECRET_KEY` 是否設定
- 確認所有必要的環境變數都已添加

### 2. 前端頁面空白
- 檢查 `NEXT_PUBLIC_API_URL` 設定
- 確認 `NODE_ENV=production`

### 3. API 連接失敗
- 檢查 `ALLOWED_ORIGINS` 是否包含正確的域名
- 確認容器端口設定為 `80`

### 4. 文件上傳失敗
- 檢查 `MAX_FILE_SIZE` 設定
- 確認存儲空間充足

## 📈 性能優化

### 環境變數優化
```bash
# 啟用生產模式優化
NEXT_TELEMETRY_DISABLED=1
NODE_OPTIONS=--max-old-space-size=2048

# 啟用緩存
REDIS_URL=redis://your-redis-url  # 如果使用 Redis
```

## 🎯 下一步

1. **設定環境變數**：複製上面的模板到 Zeabur
2. **生成安全密鑰**：替換 JWT_SECRET_KEY 和 SESSION_SECRET
3. **確認端口設定**：容器端口 80
4. **測試部署**：檢查健康端點和前端頁面
5. **創建管理員用戶**：首次訪問時註冊管理員帳號

---
**配置時間**: 2025-01-02  
**狀態**: 📋 等待用戶配置  
**下一步**: 設定環境變數並測試部署 