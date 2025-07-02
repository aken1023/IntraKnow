# 🌐 Zeabur 網絡連接問題修復指南

## 問題描述
在 Docker 鏡像推送階段出現網絡連接錯誤：
```
error: failed to do request: Head "https://registry.zeabur.cloud/...": dial tcp 10.100.0.30:443: connect: connection refused
```

## 問題原因
1. **基礎設施暫時問題**：Zeabur 註冊表服務暫時不可用
2. **鏡像過大**：大型鏡像推送容易超時
3. **網絡連接不穩定**：上傳過程中網絡中斷

## 解決方案

### 方案一：重試部署（推薦）
這通常是暫時的網絡問題，可以直接重試：

1. **等待 5-10 分鐘**：讓 Zeabur 基礎設施恢復
2. **重新觸發部署**：
   ```bash
   git commit --allow-empty -m "Retry deployment after network issue"
   git push origin main
   ```

### 方案二：使用輕量化 Dockerfile
如果重試仍然失敗，切換到輕量化版本：

1. **切換到輕量版本**：
   ```bash
   mv Dockerfile Dockerfile.full
   mv Dockerfile.lightweight Dockerfile
   ```

2. **提交變更**：
   ```bash
   git add .
   git commit -m "Switch to lightweight Docker image for better network stability"
   git push origin main
   ```

### 方案三：優化網絡設置
如果問題持續，可能需要：

1. **檢查 Zeabur 狀態**：
   - 訪問 [Zeabur 狀態頁面](https://status.zeabur.com)
   - 確認服務是否正常

2. **聯繫 Zeabur 支援**：
   - 如果是區域性網絡問題
   - 提供錯誤日誌給技術支援

## 輕量化優化說明

### Dockerfile.lightweight 優化特點：
1. **減少層數**：合併 RUN 指令減少鏡像層
2. **移除 PyTorch**：使用 CPU 推理，減少大小
3. **清理緩存**：及時清理 apt 和 npm 緩存
4. **簡化配置**：減少不必要的配置和檢查
5. **使用 --no-install-recommends**：只安裝必需的依賴

### 預期改善：
- **鏡像大小**：從 ~2GB 減少到 ~800MB
- **推送時間**：減少 60-70%
- **網絡穩定性**：更少的數據傳輸，更穩定

## 監控和診斷

### 檢查推送進度：
觀察日誌中的推送階段：
```
pushing layers 35.7s done  ← 這表示層推送成功
ERROR: failed to push     ← 這是最後的推送失敗
```

### 成功標誌：
```
✅ 所有層推送完成
✅ 鏡像成功推送到註冊表
✅ 部署開始運行
```

## 備用方案

### 如果 Docker 部署持續失敗：
1. **回到原生部署**：
   ```bash
   # 修改 zeabur.toml
   [build]
   type = "python"
   ```

2. **使用簡化的 Python 應用**：
   - 只部署後端 API
   - 前端使用其他服務（如 Vercel）

## 實用命令

### 檢查當前鏡像大小：
```bash
docker images | grep zeabur
```

### 本地測試 Docker 構建：
```bash
docker build -f Dockerfile.lightweight -t test-image .
docker run -p 8080:80 test-image
```

---
**修復時間**: 2025-01-02  
**狀態**: 📡 網絡連接問題  
**建議**: 先重試，再使用輕量化版本 