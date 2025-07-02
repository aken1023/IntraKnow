# 🚀 Zeabur 快速部署指南

## 📋 部署前檢查

已為您創建完整的 Zeabur Docker 部署配置：

✅ **Dockerfile** - 多階段構建，前後端整合  
✅ **nginx.conf** - Nginx 代理配置  
✅ **supervisord.conf** - 進程管理配置  
✅ **start.sh** - 啟動腳本  
✅ **zeabur.toml** - Zeabur 部署配置  
✅ **package.json** - Node.js 依賴（已調整生產環境）  
✅ **requirements-zeabur-fixed.txt** - Python 依賴  

## 🎯 快速部署步驟

### 1. 提交代碼
```bash
git add .
git commit -m "Add Zeabur Docker deployment configuration"
git push origin main
```

### 2. 在 Zeabur 部署
1. 登錄 [Zeabur](https://zeabur.com)
2. 創建新專案
3. 點擊「Add Service」→「Git Repository」
4. 選擇您的 GitHub 儲存庫
5. Zeabur 會自動檢測 `zeabur.toml` 和 `Dockerfile`
6. 點擊「Deploy」

### 3. 等待部署完成
- 構建時間約 5-10 分鐘
- 查看部署日誌確認狀態
- 部署成功後會獲得一個 URL

### 4. 驗證部署
訪問您的應用：
```bash
# 檢查健康狀態
curl https://your-app.zeabur.app/api/health

# 訪問前端
curl https://your-app.zeabur.app/
```

## 🏗️ 部署架構

```
Zeabur → Docker Container (Port 80)
├── Nginx (反向代理)
├── Frontend: Next.js (Port 3000)
└── Backend: FastAPI (Port 8000)
```

## 📊 資源配置

- **記憶體**: 2GB RAM
- **CPU**: 2 核心
- **磁盤**: 10GB
- **實例**: 1-2 個（自動擴展）

## 🔧 環境變數（已預設）

```
NODE_ENV=production
PYTHONUNBUFFERED=1
EMBEDDING_MODEL=BAAI/bge-base-zh
MODEL_NAME=deepseek-chat
NEXT_PUBLIC_API_URL=/api
```

## 📝 API 端點

部署成功後可用的端點：

- **前端**: `https://your-app.zeabur.app/`
- **健康檢查**: `https://your-app.zeabur.app/api/health`
- **用戶註冊**: `https://your-app.zeabur.app/api/auth/register`
- **用戶登錄**: `https://your-app.zeabur.app/api/auth/login`
- **知識庫查詢**: `https://your-app.zeabur.app/api/query`

## 🛠️ 故障排除

### 如果構建失敗
1. 檢查 GitHub 儲存庫是否包含所有配置文件
2. 查看 Zeabur 構建日誌的錯誤信息
3. 確認 `Dockerfile` 和依賴文件正確

### 如果應用無法啟動
1. 檢查 Zeabur 運行時日誌
2. 驗證環境變數設置
3. 確認端口配置正確

### 如果前端空白
1. 檢查 Next.js 構建是否成功
2. 驗證 Nginx 代理配置
3. 確認靜態文件路徑正確

## 📈 監控建議

- 定期檢查應用健康狀態
- 監控資源使用情況
- 查看錯誤日誌
- 設置告警通知

## 🔄 更新部署

每次代碼更新後，只需：
```bash
git push origin main
```
Zeabur 會自動重新部署。

## 📞 技術支援

如遇問題，請查看：
1. Zeabur 控制台日誌
2. `ZEABUR_DOCKER_DEPLOYMENT.md` 詳細文檔
3. GitHub Issues

---

**🎉 恭喜！您的 IntraKnow 企業知識庫系統現在可以在 Zeabur 上運行了！** 