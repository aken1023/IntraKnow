# 貢獻指南

感謝您考慮為 LlamaIndex + FAISS + DeepSeek LLM 企業知識庫系統做出貢獻！這個專案旨在提供高效的文檔檢索和問答服務，我們歡迎各種形式的貢獻。

## 如何貢獻

### 報告問題

如果您發現問題或有功能建議，請透過 GitHub Issues 提交，包括：

- 清晰的問題描述
- 重現步驟
- 預期與實際結果
- 環境資訊（作業系統、Python 版本等）
- 相關日誌或截圖

### 提交更改

1. Fork 此代碼庫
2. 創建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟一個 Pull Request

### Pull Request 流程

1. 確保您的 PR 有明確的標題和詳細描述
2. 更新文檔以反映代碼更改
3. 您的 PR 需要至少一位維護者審核後才能合併
4. 請確保所有自動化測試都通過

## 開發設置

### 前置需求

- Python 3.10+
- Node.js 18+
- Docker & Docker Compose（可選）

### 本地開發環境設置

```bash
# 克隆代碼庫
git clone https://github.com/your-username/llamaindex-faiss-system.git
cd llamaindex-faiss-system

# 設置環境變數
# 將 .env.example 複製為 .env 並編輯
cp .env.example .env

# 安裝後端依賴
cd scripts
pip install -r requirements.txt

# 返回專案根目錄
cd ..

# 安裝前端依賴
npm install
```

### 開發指南

#### 後端開發

- 使用 FastAPI 進行 API 開發
- 遵循 PEP 8 程式碼風格
- 對於新功能，請添加相應的測試
- 使用類型提示增強代碼可讀性

#### 前端開發

- 使用 Next.js 框架和 React 進行前端開發
- 遵循 ESLint 和 Prettier 配置
- 組件應該採用模塊化設計
- 保持前後端狀態同步

## 代碼規範

- 使用清晰、描述性的變數名和函數名
- 添加適當的註釋和文檔字符串
- 遵循 DRY（不重複自己）原則
- 優先使用非同步處理以提高性能
- 關注錯誤處理和邊界情況

## 技術文檔

主要組件：

- **FastAPI 服務**：`scripts/api_server.py` 提供 REST API
- **知識庫核心**：`scripts/setup_knowledge_base.py` 負責索引和查詢
- **Next.js 前端**：`app/` 目錄包含使用者介面
- **Docker 設置**：`Dockerfile` 和 `docker-compose.yml` 用於容器化部署

## 授權

通過提交 PR，您同意您的貢獻將在 [MIT 授權](../LICENSE) 下發布。 