#!/bin/bash

# 設置顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 顯示橫幅
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║             ${GREEN}IntraKnow 企業知識庫系統${BLUE}                    ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║                 ${YELLOW}一鍵啟動器 (Unix)${BLUE}                      ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo

# 檢查 Python
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo -e "${RED}[錯誤] 未找到 Python。請安裝 Python 3.10 或更高版本。${NC}"
    echo
    echo "Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip python3-venv"
    echo "CentOS/RHEL: sudo yum install python3 python3-pip"
    echo "macOS: brew install python3"
    exit 1
fi

# 檢查 Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}[錯誤] 未找到 Node.js。請安裝 Node.js 和 npm。${NC}"
    echo
    echo "Ubuntu/Debian: sudo apt update && sudo apt install nodejs npm"
    echo "CentOS/RHEL: sudo yum install nodejs npm"
    echo "macOS: brew install node"
    exit 1
fi

echo -e "${GREEN}[信息] 正在啟動 IntraKnow 系統...${NC}"
echo

# 確定 Python 命令
if command -v python3 &> /dev/null; then
    PYTHON_CMD=python3
else
    PYTHON_CMD=python
fi

# 執行統一啟動腳本
$PYTHON_CMD start_all.py

# 腳本退出後
echo
echo -e "${GREEN}[信息] 系統已停止${NC}" 