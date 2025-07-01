# Vercel 部署指南

本文檔提供了將企業知識庫系統部署到 Vercel 平台的詳細指南。

## 部署架構

此系統採用以下架構進行部署：

1. **前端應用** - 使用 Next.js 框架，部署在 Vercel 上
2. **API 服務** - 使用 FastAPI，需要單獨部署在支援 Python 的平台上
3. **RWD 設計** - 採用響應式網頁設計，支援各種裝置尺寸

## 部署前準備

### 1. 註冊帳號

- 在 [Vercel](https://vercel.com) 註冊帳號
- 在您選擇的 Python 支援平台上註冊帳號（例如 Zeabur、Render、Railway 等）

### 2. 獲取必要的 API 密鑰

- DeepSeek API 密鑰（用於 LLM 查詢）

### 3. 準備好代碼倉庫

- 確保代碼已推送到 GitHub、GitLab 或 Bitbucket

## 部署步驟

### 1. 部署 API 服務

按照 `ZEABUR_DEPLOYMENT.md` 或其他平台的指南部署 API 服務。

### 2. 在 Vercel 上部署前端

1. 登入 Vercel 控制台
2. 點擊「New Project」
3. 導入您的 Git 倉庫
4. 配置部署設置：
   - **Framework Preset**: Next.js
   - **Build and Output Settings**: 保持默認設置
   - **Environment Variables**: 添加以下變量：
     - `NEXT_PUBLIC_API_URL`: 指向您部署的 API 服務 URL
     - `NEXT_PUBLIC_BASE_URL`: 指向 Vercel 項目的 URL（可在首次部署後添加）

5. 點擊「Deploy」開始部署

### 3. 配置域名（可選）

1. 在 Vercel 專案設置中，前往「Domains」頁籤
2. 添加您的自訂域名
3. 按照指引設置 DNS 記錄

### 4. 啟用自動部署（可選）

默認情況下，當您推送更改到 Git 倉庫的主分支時，Vercel 會自動重新部署您的應用。

## 驗證部署

部署完成後，可以通過以下方式驗證系統是否正常運行：

1. 訪問 Vercel 提供的 URL 或您配置的自訂域名
2. 測試前端功能，包括在不同裝置上的響應式設計
3. 測試 API 整合，包括知識庫查詢功能

## RWD 架構說明

本專案採用了全面的響應式網頁設計（RWD）架構：

1. **斷點系統**：使用 Tailwind CSS 配置的斷點，支援從手機到大屏幕顯示器的各種尺寸
   - xs: 390px
   - sm: 640px
   - md: 768px
   - lg: 1024px
   - xl: 1280px
   - 2xl: 1536px
   - 3xl: 1920px

2. **裝置檢測**：使用 ViewportProvider 動態檢測用戶裝置類型和螢幕尺寸

3. **響應式組件**：所有 UI 組件都經過設計，能夠自動適應不同的螢幕尺寸

4. **容器系統**：使用 ResponsiveContainer 組件統一管理佈局的最大寬度和邊距

## 常見問題

### API 連接問題

如果前端無法連接到 API，請檢查：

1. `NEXT_PUBLIC_API_URL` 環境變數是否正確設置
2. API 服務是否正常運行
3. CORS 設置是否允許來自 Vercel 域名的請求

### 圖像優化問題

如果圖像顯示有問題，請確保：

1. 已在 `next.config.mjs` 的 `images.domains` 中配置了正確的域名
2. 使用了 Next.js 的 Image 組件而非普通的 img 標籤

### 響應式設計調試

如果響應式設計在某些設備上顯示不正確：

1. 使用瀏覽器的設備模擬功能進行測試
2. 檢查 ViewportProvider 是否正確運行
3. 檢查組件是否使用了正確的響應式類名

### 部署後靜態資源問題

如果部署後靜態資源（如圖像、字體）無法加載：

1. 確保資源放在 `/public` 目錄下
2. 使用絕對路徑引用資源（例如 `/images/logo.png`） 