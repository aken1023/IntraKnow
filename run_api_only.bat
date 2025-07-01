@echo off
setlocal EnableDelayedExpansion

echo ======================================================
echo   LlamaIndex + FAISS 知識庫系統 - 僅後端API
echo ======================================================

:: 創建目錄（如果不存在）
if not exist "documents" mkdir documents
if not exist "faiss_index" mkdir faiss_index

:: 檢查是否有虛擬環境
if not exist "venv\Scripts\python.exe" (
    echo [設置] 創建虛擬環境...
    python -m venv venv
    echo [設置] 安裝Python依賴...
    call venv\Scripts\pip install -r scripts\requirements.txt
) else (
    echo [設置] 使用現有虛擬環境
)

:: 啟動後端API
echo [後端] 啟動API服務...
echo.
echo ======================================================
venv\Scripts\python.exe scripts\api_server.py 