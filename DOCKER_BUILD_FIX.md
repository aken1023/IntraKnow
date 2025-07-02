# 🔧 Docker 構建修復說明

## 問題描述
在 Zeabur 部署時遇到以下錯誤：
```
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/app/package.json'
```

## 根本原因
Dockerfile 第一階段（frontend-builder）中，使用了 `COPY . .` 來複製所有文件，但由於 Docker 構建上下文的限制，某些文件可能無法正確複製到構建環境中。

## 解決方案
修改 Dockerfile 的第一階段，明確指定需要複製的文件和目錄：

### 修復前
```dockerfile
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run build
```

### 修復後
```dockerfile
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
```

## 修復的優點
1. **明確性**: 清楚地指定需要複製的文件和目錄
2. **可靠性**: 避免因 Docker 上下文問題導致的文件遺漏
3. **效率性**: 只複製必要的文件，減少構建時間
4. **調試友好**: 容易識別哪些文件被複製

## 驗證方法
```bash
git add .
git commit -m "Fix Docker build - explicit file copying"
git push origin main
```

然後在 Zeabur 控制台重新部署，應該能看到成功的構建過程。

---
**修復時間**: 2025-01-02  
**狀態**: ✅ 已修復 