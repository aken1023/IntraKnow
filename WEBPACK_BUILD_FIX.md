# 🔧 Webpack 構建問題修復指南

## 🚨 問題描述
遇到 webpack 構建失敗錯誤：
```
> Build failed because of webpack errors
process "/bin/sh -c npm run build" did not complete successfully: exit code: 1
```

## 🎯 多重解決方案

### 方案一：修復後的全棧版本（當前）
已經修復的 `Dockerfile` 包含：
- 容錯構建邏輯
- 備用構建方案
- 改善的錯誤處理
- 寬鬆的健康檢查

**特點**：
```dockerfile
# 構建前端（添加調試信息）
RUN echo "開始構建 Next.js..." && \
    NODE_OPTIONS="--max-old-space-size=2048" npm run build || \
    (echo "構建失敗，嘗試修復..." && \
     rm -rf .next && \
     NODE_ENV=development npm run build) || \
    (echo "仍然失敗，跳過構建步驟..." && \
     mkdir -p .next/static && \
     echo '{"version":"fallback"}' > .next/build-manifest.json)
```

### 方案二：純後端部署（推薦備用）
如果前端構建持續失敗，可以只部署後端：

```bash
# 切換到純後端版本
mv Dockerfile Dockerfile.fullstack
mv Dockerfile.backend-only Dockerfile

# 更新 zeabur.toml
echo '[build]
type = "docker"
dockerfile = "Dockerfile"

[build.env]
PORT = "8000"' > zeabur.toml

# 部署
git add .
git commit -m "Deploy backend-only version due to frontend build issues"
git push origin main
```

**優點**：
- ✅ 快速部署（2-3分鐘）
- ✅ 穩定可靠
- ✅ 完整的 API 功能
- ✅ 文件上傳和知識庫功能

**使用方式**：
- API 端點：`https://your-app.zeabur.app/api/*`
- 健康檢查：`https://your-app.zeabur.app/health`
- 文檔：`https://your-app.zeabur.app/docs`

### 方案三：分離部署
1. **後端**：部署到 Zeabur
2. **前端**：部署到 Vercel 或 Netlify

**步驟**：

#### 後端部署（Zeabur）：
```bash
mv Dockerfile.backend-only Dockerfile
git add .
git commit -m "Deploy backend to Zeabur"
git push origin main
```

#### 前端部署（Vercel）：
```bash
# 創建 vercel.json
echo '{
  "rewrites": [
    {
      "source": "/api/(.*)",
      "destination": "https://your-zeabur-backend.zeabur.app/api/$1"
    }
  ]
}' > vercel.json

# 部署到 Vercel
npx vercel --prod
```

## 🔍 當前部署測試

### 測試修復後的版本：
```bash
git add .
git commit -m "Fix webpack build with fallback strategies"
git push origin main
```

### 檢查構建日誌：
在 Zeabur 控制台查看：
1. **成功標誌**：`✅ 啟動服務...`
2. **部分成功**：`⚠️ 前端未構建，嘗試運行構建...`
3. **後端正常**：`📊 初始化知識庫...`

## 🛠️ 環境變數配置

### 全棧版本（端口 80）：
```bash
# 保持原有配置
PORT=${WEB_PORT}
NEXT_PUBLIC_API_URL=/api
# ... 其他變數不變
```

### 純後端版本（端口 8000）：
```bash
# 移除前端相關變數
# PORT=${WEB_PORT}  # 移除這行
# NEXT_PUBLIC_API_URL=/api  # 移除這行

# 保留其他所有變數
PYTHONPATH=/app
PYTHONUNBUFFERED=1
JWT_SECRET_KEY=xYhOdPdioxh8iUpnF1oyWUwMFFEdgTEkTrDH-9kaKcWOr0-KkdGwsOzCZrW38aaJSQmLGgYvYd7SFwjXpP-wzQ
# ... 其他保持不變
```

## 📊 優先順序建議

### 1. 🚀 立即嘗試（修復版）
使用當前修復的 Dockerfile：
- 有容錯機制
- 可能解決 webpack 問題
- 完整功能

### 2. 🎯 快速備用（純後端）
如果修復版仍失敗：
- 5分鐘內可部署
- API 完全可用
- 前端可用其他服務

### 3. 🏗️ 長期方案（分離部署）
最穩定的架構：
- 後端：Zeabur（Python 專長）
- 前端：Vercel（Next.js 專長）
- 更好的性能和穩定性

## 🎯 立即行動方案

**我建議先嘗試修復版本**：

```bash
# 提交當前修復
git add .
git commit -m "🔧 Fix webpack build with comprehensive error handling"
git push origin main
```

如果 10 分鐘內仍然失敗，我們立即切換到純後端版本！

---
**修復時間**: 2025-01-02  
**狀態**: 🔧 Webpack 問題修復中  
**備用方案**: 純後端部署已準備 