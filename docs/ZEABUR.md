# Zeabur 部署指南

## 部署前準備

1. 在 [Zeabur](https://zeabur.com) 註冊一個帳號
2. 取得 DeepSeek API 密鑰，用於 LLM 查詢功能
3. 準備好專案代碼並推送到 Git 倉庫

## 所需環境變數

所有配置都通過環境變數進行設置，無需 `.env` 文件：

- `DEEPSEEK_API_KEY`: DeepSeek API 密鑰（**必需**）
- `EMBEDDING_MODEL`: 嵌入模型名稱 (預設: `BAAI/bge-base-zh`)
- `MODEL_NAME`: 語言模型名稱 (預設: `deepseek-chat`)
- `NEXT_PUBLIC_API_URL`: API 服務的 URL (生產環境下設置)

## 部署方式一：使用 Zeabur 網頁界面

1. 登入 Zeabur 控制台
2. 點擊「建立專案」
3. 選擇從 Git 倉庫部署
4. 連接並選擇您的 Git 倉庫
5. Zeabur 將自動檢測 `zeabur.toml` 配置檔案並設置服務
6. 在「環境變數」頁籤中設置所有必要的環境變數
7. 設置持久化存儲卷 (針對 `/app/documents`, `/app/faiss_index` 和 `/app/logs`)
8. 配置自訂網域或使用 Zeabur 提供的預設域名

## 部署方式二：使用 GitHub Actions 自動部署

1. 在您的 GitHub 倉庫中設置以下密鑰:
   - `ZEABUR_TOKEN`: Zeabur API 令牌
   - `ZEABUR_PROJECT`: Zeabur 專案 ID
   - `NEXT_PUBLIC_API_URL`: 前端訪問 API 的 URL
   - `DEEPSEEK_API_KEY`: DeepSeek API 密鑰

2. 確保 `.github/workflows/zeabur-deploy.yml` 文件已添加到您的倉庫中

3. 當您推送代碼到 `main` 分支時，GitHub Actions 將自動觸發部署流程

## 驗證部署

部署完成後，可以通過以下方式驗證系統是否正常運行:

1. 訪問前端應用: `https://您的網域/`
2. 檢查 API 文檔: `https://您的網域/api/docs`
3. 查看系統狀態: `https://您的網域/api/status`

## 常見問題

- **API 和前端分離部署**: 如果您將 API 和前端分別部署為不同服務，請確保設置正確的 `NEXT_PUBLIC_API_URL` 環境變數
- **文件上傳失敗**: 確認持久化存儲已正確設置
- **索引建立失敗**: 首次運行時需確保 `/app/documents` 目錄已包含至少一份文檔 