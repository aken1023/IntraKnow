@echo off
setlocal EnableDelayedExpansion

echo ======================================================
echo   LlamaIndex + FAISS 知識庫系統 - 無語音版本
echo ======================================================

:: 創建目錄（如果不存在）
if not exist "documents" mkdir documents
if not exist "faiss_index" mkdir faiss_index

:: 檢查是否有虛擬環境
if not exist "venv\Scripts\python.exe" (
    echo [設置] 創建虛擬環境...
    python -m venv venv
)

:: 啟動後端（在背景執行）
echo [後端] 啟動中...
start cmd /c "venv\Scripts\python.exe scripts\api_server.py"
echo [後端] API 服務已在 http://localhost:8000 啟動

:: 等待後端啟動
echo [系統] 等待後端服務啟動...
timeout /t 3 /nobreak > nul

:: 安裝前端依賴（如果尚未安裝）
if not exist "node_modules" (
    echo [前端] 安裝依賴中...
    call npm install --legacy-peer-deps
)

:: 啟動前端
echo [前端] 啟動中...
start cmd /c "npx next dev"

echo.
echo ======================================================
echo   系統已啟動！
echo.
echo   * 前端界面: http://localhost:3000
echo   * API 服務: http://localhost:8000
echo   * API 文檔: http://localhost:8000/docs
echo ======================================================
echo.
echo 按 Ctrl+C 然後輸入 Y 來關閉所有服務
echo.

:: 等待用戶按 Ctrl+C
pause > nul 