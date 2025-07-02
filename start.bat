@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║             IntraKnow 企業知識庫系統                    ║
echo ║                                                          ║
echo ║                 一鍵啟動器 (Windows)                    ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: 檢查 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到 Python。請安裝 Python 3.10 或更高版本。
    echo.
    echo 下載地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

:: 檢查 Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到 Node.js。請安裝 Node.js 和 npm。
    echo.
    echo 下載地址: https://nodejs.org/
    pause
    exit /b 1
)

echo [信息] 正在啟動 IntraKnow 系統...
echo.

:: 執行統一啟動腳本
python start_all.py

:: 腳本退出後
echo.
echo [信息] 系統已停止
pause 