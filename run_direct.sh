#!/bin/bash

# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================"
echo -e "  LlamaIndex + FAISS 知識庫系統 - 直接啟動腳本"
echo -e "======================================================${NC}"

# 創建目錄（如果不存在）
mkdir -p documents faiss_index

# 檢查是否有虛擬環境
if [ ! -f "venv/bin/python" ]; then
    echo -e "${YELLOW}[設置] 創建虛擬環境...${NC}"
    python3 -m venv venv
fi

# 啟動後端（在背景執行）
echo -e "${GREEN}[後端] 啟動中...${NC}"
source venv/bin/activate
nohup python scripts/api_server.py > api_server.log 2>&1 &
BACKEND_PID=$!
echo -e "${GREEN}[後端] API 服務已在 http://localhost:8000 啟動 (PID: $BACKEND_PID)${NC}"

# 等待後端啟動
echo -e "${YELLOW}[系統] 等待後端服務啟動...${NC}"
sleep 3

# 安裝前端依賴（如果尚未安裝）
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}[前端] 安裝依賴中...${NC}"
    npm install --legacy-peer-deps
fi

# 啟動前端
echo -e "${GREEN}[前端] 啟動中...${NC}"
echo -e "${YELLOW}[前端] 如果遇到錯誤，請嘗試在新的終端窗口運行: npm run dev --legacy-peer-deps${NC}"
npx next dev > frontend.log 2>&1 &
FRONTEND_PID=$!

echo ""
echo -e "${BLUE}======================================================"
echo -e "  系統已啟動！"
echo -e ""
echo -e "  * 前端界面: ${GREEN}http://localhost:3000${BLUE}"
echo -e "  * API 服務: ${GREEN}http://localhost:8000${BLUE}"
echo -e "  * API 文檔: ${GREEN}http://localhost:8000/docs${BLUE}"
echo -e "======================================================${NC}"
echo ""
echo -e "後端日誌: tail -f api_server.log"
echo -e "前端日誌: tail -f frontend.log"
echo -e "按 ${RED}Ctrl+C${NC} 來關閉所有服務"
echo ""

# 清理函數
cleanup() {
    echo -e "\n${YELLOW}正在關閉服務...${NC}"
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}所有服務已關閉${NC}"
    exit 0
}

# 註冊信號處理器
trap cleanup SIGINT SIGTERM

# 保持腳本運行
wait 