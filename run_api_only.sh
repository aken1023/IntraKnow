#!/bin/bash

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================"
echo -e "  LlamaIndex + FAISS 知識庫系統 - 僅後端API"
echo -e "======================================================${NC}"

# 創建目錄（如果不存在）
mkdir -p documents faiss_index

# 檢查是否有虛擬環境
if [ ! -f "venv/bin/python" ]; then
    echo -e "${YELLOW}[設置] 創建虛擬環境...${NC}"
    python3 -m venv venv
    echo -e "${YELLOW}[設置] 安裝Python依賴...${NC}"
    venv/bin/pip install -r scripts/requirements.txt
else
    echo -e "${GREEN}[設置] 使用現有虛擬環境${NC}"
fi

# 啟動後端API
echo -e "${GREEN}[後端] 啟動API服務...${NC}"
echo ""
echo -e "${BLUE}======================================================${NC}"
source venv/bin/activate
python scripts/api_server.py 