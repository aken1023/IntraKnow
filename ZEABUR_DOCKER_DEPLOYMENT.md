# IntraKnow 企業知識庫系統 - Zeabur Docker 部署指南

## 📋 概述

本指南將幫助您在 Zeabur 平台上使用 Docker 部署 IntraKnow 企業知識庫系統，包含前端（Next.js）和後端（FastAPI）的完整整合。

## 🏗️ 架構說明

### 部署架構
```
Internet → Zeabur Load Balancer → Nginx (Port 80) → {
    Frontend: Next.js (Port 3000)
    Backend:  FastAPI (Port 8000)
}
```

### 技術棧
- **前端**: Next.js 14 + Tailwind CSS + TypeScript
- **後端**: FastAPI + SQLAlchemy + FAISS
- **代理**: Nginx
- **進程管理**: Supervisor
- **容器**: Docker (多階段構建)

## 🚀 部署步驟

### 1. 準備代碼
確保您的代碼包含以下關鍵文件：
```
├── Dockerfile               # Docker 構建配置
├── nginx.conf              # Nginx 代理配置
├── supervisord.conf        # 進程管理配置
├── start.sh                # 啟動腳本
├── zeabur.toml            # Zeabur 部署配置
├── package.json           # Node.js 依賴
└── scripts/
    └── requirements-zeabur-fixed.txt  # Python 依賴
```

### 2. 登錄 Zeabur
1. 訪問 [Zeabur](https://zeabur.com)
2. 使用 GitHub 帳號登錄
3. 創建新的專案

### 3. 部署應用
1. 點擊「Add Service」
2. 選擇「Git Repository」
3. 連接您的 GitHub 儲存庫
4. Zeabur 會自動檢測到 `zeabur.toml` 配置文件
5. 點擊「Deploy」開始部署

### 4. 配置環境變數（可選）
在 Zeabur 控制台中設置以下環境變數：
```
NODE_ENV=production
PYTHONUNBUFFERED=1
EMBEDDING_MODEL=BAAI/bge-base-zh
MODEL_NAME=deepseek-chat
NEXT_PUBLIC_API_URL=/api
```

## 📁 關鍵配置文件說明

### Dockerfile
- **多階段構建**: 先構建前端，再組裝運行環境
- **系統依賴**: Python 3.11 + Node.js 18 + Nginx + Supervisor
- **AI 模型**: PyTorch CPU 版本，適合雲端部署
- **端口**: 對外暴露 80 端口

### nginx.conf
- **前端代理**: `/` → `localhost:3000`
- **API 代理**: `/api/` → `localhost:8000/api/`
- **認證代理**: `/auth/` → `localhost:8000/auth/`
- **健康檢查**: `/health` → `localhost:8000/health`

### supervisord.conf
管理三個服務的啟動順序：
1. **Nginx** (優先級 100)
2. **Backend** (優先級 200)
3. **Frontend** (優先級 300)

### zeabur.toml
- **構建類型**: Docker
- **資源配置**: 2GB RAM, 2 CPU, 10GB 磁盤
- **健康檢查**: `/api/health`
- **自動擴展**: 1-2 實例

## 🔧 本地測試

在部署到 Zeabur 之前，建議先在本地測試 Docker 容器：

```bash
# 構建鏡像
docker build -t intraknow .

# 運行容器
docker run -p 80:80 intraknow

# 測試服務
curl http://localhost:80/api/health
curl http://localhost:80/
```

## 📊 監控和維護

### 健康檢查
- **端點**: `/api/health`
- **間隔**: 30 秒
- **超時**: 10 秒
- **重試**: 3 次

### 日誌查看
在 Zeabur 控制台中可以查看：
- 構建日誌
- 運行時日誌
- 錯誤日誌

### 資源監控
- CPU 使用率
- 記憶體使用率
- 網絡流量
- 磁盤使用量

## 🛠️ 故障排除

### 常見問題

#### 1. 構建失敗
**症狀**: Docker 構建過程中失敗
**解決方案**:
- 檢查 `Dockerfile` 語法
- 確認所有依賴文件存在
- 查看構建日誌中的具體錯誤

#### 2. 服務無法啟動
**症狀**: 容器啟動後立即退出
**解決方案**:
- 檢查 `start.sh` 腳本權限
- 驗證 `supervisord.conf` 配置
- 查看容器日誌

#### 3. 前端無法訪問
**症狀**: 可以訪問 API 但前端頁面空白
**解決方案**:
- 檢查 Next.js 構建是否成功
- 確認 Nginx 代理配置正確
- 驗證環境變數設置

#### 4. API 請求失敗
**症狀**: 前端無法調用後端 API
**解決方案**:
- 檢查 Nginx 代理路徑配置
- 確認後端服務正在運行
- 驗證 CORS 設置

### 調試命令

```bash
# 進入運行中的容器
docker exec -it <container_id> /bin/bash

# 查看服務狀態
supervisorctl status

# 重啟特定服務
supervisorctl restart backend
supervisorctl restart frontend
supervisorctl restart nginx

# 查看日誌
tail -f /var/log/backend_error.log
tail -f /var/log/frontend_error.log
tail -f /var/log/nginx_error.log
```

## 🔄 更新部署

1. 推送代碼到 GitHub
2. Zeabur 會自動觸發重新部署
3. 監控部署狀態
4. 驗證新版本功能

## 📈 性能優化

### 建議配置
- **實例數**: 根據流量調整（1-2 個實例）
- **資源分配**: 2GB RAM, 2 CPU 核心
- **緩存策略**: 利用 Nginx 靜態文件緩存
- **數據庫**: 使用持久化存儲

### 擴展選項
- 增加實例數量應對高流量
- 升級資源配置提升性能
- 添加 CDN 加速靜態資源
- 使用外部數據庫服務

## 📞 支援

如果在部署過程中遇到問題：
1. 查看 Zeabur 控制台的日誌
2. 檢查本文檔的故障排除部分
3. 確認所有配置文件都已正確設置
4. 在本地環境中重現和測試

## 📝 更新日誌

- **v2.0.0**: 初始 Docker 部署配置
- 前後端整合部署
- Nginx 代理配置
- Supervisor 進程管理
- 完整的健康檢查和監控 