@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║             IntraKnow 企業知識庫系統                    ║
echo ║                                                          ║
echo ║               簡化版一鍵啟動器                           ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: 檢查系統需求
echo [檢查] 正在檢查系統需求...

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到 Python。請安裝 Python 3.10+
    pause
    exit /b 1
)

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到 Node.js。請安裝 Node.js 和 npm
    pause
    exit /b 1
)

echo [成功] 系統需求檢查通過

:: 創建必要目錄
if not exist "user_documents" mkdir user_documents
if not exist "user_indexes" mkdir user_indexes
if not exist "logs" mkdir logs

:: 檢查 Node.js 依賴
if not exist "node_modules" (
    echo [安裝] 正在安裝前端依賴...
    call npm install
    if %errorlevel% neq 0 (
        echo [錯誤] 前端依賴安裝失敗
        pause
        exit /b 1
    )
)

:: 設置環境變量
set NEXT_PUBLIC_API_URL=http://localhost:8000

echo.
echo [啟動] 正在啟動服務...
echo.
echo [後端] 啟動 API 服務器 (端口 8000)...

:: 在新視窗中啟動後端
start "後端 API 服務器" /min python scripts/auth_api_server.py

:: 等待後端啟動
timeout /t 5 /nobreak >nul

echo [前端] 啟動 Next.js 應用 (端口 3000)...

:: 在新視窗中啟動前端
start "前端 Next.js 應用" /min npm run dev

:: 等待前端啟動
timeout /t 8 /nobreak >nul

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                      系統已啟動                         ║
echo ║                                                          ║
echo ║  前端應用: http://localhost:3000                        ║
echo ║  後端 API: http://localhost:8000                        ║
echo ║  API 文檔: http://localhost:8000/docs                   ║
echo ║                                                          ║
echo ║  測試帳號: admin/admin123, test/test123                 ║
echo ║                                                          ║
echo ║  關閉時請分別關閉兩個服務視窗                           ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

echo [信息] 如需檢查日誌，請查看 logs/ 目錄
echo [信息] 按任意鍵打開瀏覽器訪問系統...
pause >nul

:: 打開瀏覽器
start http://localhost:3000

echo.
echo [提示] 系統已在背景運行
echo [提示] 要停止系統，請關閉兩個服務視窗
pause 