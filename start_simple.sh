#!/bin/bash

# 設置顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 顯示橫幅
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║             ${GREEN}IntraKnow 企業知識庫系統${BLUE}                    ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║                 ${YELLOW}簡化版一鍵啟動器${BLUE}                       ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo

# 檢查系統需求
echo -e "${YELLOW}[檢查] 正在檢查系統需求...${NC}"

# 確定 Python 命令
if command -v python3 &> /dev/null; then
    PYTHON_CMD=python3
elif command -v python &> /dev/null; then
    PYTHON_CMD=python
else
    echo -e "${RED}[錯誤] 未找到 Python。請安裝 Python 3.10+${NC}"
    exit 1
fi

# 檢查 Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}[錯誤] 未找到 Node.js。請安裝 Node.js 和 npm${NC}"
    exit 1
fi

echo -e "${GREEN}[成功] 系統需求檢查通過${NC}"

# 創建必要目錄
mkdir -p user_documents user_indexes logs

# 檢查 Node.js 依賴
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}[安裝] 正在安裝前端依賴...${NC}"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}[錯誤] 前端依賴安裝失敗${NC}"
        exit 1
    fi
fi

# 設置環境變量
export NEXT_PUBLIC_API_URL=http://localhost:8000

echo
echo -e "${BLUE}[啟動] 正在啟動服務...${NC}"
echo

# 啟動後端
echo -e "${GREEN}[後端] 啟動 API 服務器 (端口 8000)...${NC}"
$PYTHON_CMD scripts/auth_api_server.py &
BACKEND_PID=$!

# 等待後端啟動
sleep 5

# 啟動前端
echo -e "${BLUE}[前端] 啟動 Next.js 應用 (端口 3000)...${NC}"
npm run dev &
FRONTEND_PID=$!

# 等待前端啟動
sleep 8

echo
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      ${GREEN}系統已啟動${BLUE}                         ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║  ${GREEN}前端應用: http://localhost:3000${BLUE}                        ║${NC}"
echo -e "${BLUE}║  ${GREEN}後端 API: http://localhost:8000${BLUE}                        ║${NC}"
echo -e "${BLUE}║  ${GREEN}API 文檔: http://localhost:8000/docs${BLUE}                   ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║  ${YELLOW}測試帳號: admin/admin123, test/test123${BLUE}                 ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║  ${PURPLE}按 Ctrl+C 停止所有服務${BLUE}                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}[信息] 如需檢查日誌，請查看 logs/ 目錄${NC}"
echo -e "${YELLOW}[信息] 正在等待用戶中斷...${NC}"

# 清理函數
cleanup() {
    echo
    echo -e "${YELLOW}[系統] 正在關閉服務...${NC}"
    
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${GREEN}[後端] 停止 API 服務器...${NC}"
        kill $BACKEND_PID
    fi
    
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${BLUE}[前端] 停止 Next.js 應用...${NC}"
        kill $FRONTEND_PID
    fi
    
    echo -e "${GREEN}✓ 所有服務已安全關閉${NC}"
    exit 0
}

# 設置中斷處理
trap cleanup SIGINT SIGTERM

# 等待用戶中斷
wait 