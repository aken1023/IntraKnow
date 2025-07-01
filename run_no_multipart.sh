#!/bin/bash

echo "======================================================"
echo "  LlamaIndex + FAISS 知識庫系統 - 無 python-multipart 運行腳本"
echo "======================================================"

# 創建目錄（如果不存在）
mkdir -p documents
mkdir -p faiss_index
mkdir -p audio_files

# 檢查是否有虛擬環境
if [ ! -f "venv/bin/python" ]; then
    echo "[設置] 創建虛擬環境..."
    python3 -m venv venv
fi

# 啟動後端（在背景執行）
echo "[後端] 啟動中..."
source venv/bin/activate
nohup python scripts/api_server.py > api_server.log 2>&1 &
API_PID=$!
echo "[後端] API 服務已在 http://localhost:8000 啟動 (PID: $API_PID)"

# 等待後端啟動
echo "[系統] 等待後端服務啟動..."
sleep 3

# 安裝前端依賴（如果尚未安裝）
if [ ! -d "node_modules" ]; then
    echo "[前端] 安裝依賴中..."
    npm install --legacy-peer-deps
fi

# 啟動前端
echo "[前端] 啟動中..."
nohup npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!
echo "[前端] Next.js 服務已啟動 (PID: $FRONTEND_PID)"

echo
echo "======================================================"
echo "  系統已啟動！"
echo
echo "  * 前端界面: http://localhost:3000"
echo "  * API 服務: http://localhost:8000"
echo "  * API 文檔: http://localhost:8000/docs"
echo "======================================================"
echo
echo "進程 ID:"
echo "  - API 服務: $API_PID"
echo "  - 前端服務: $FRONTEND_PID"
echo
echo "要停止服務，請執行: kill $API_PID $FRONTEND_PID"
echo
echo "按 Ctrl+C 退出此提示（服務將繼續在背景運行）"

# 等待用戶按 Ctrl+C
read -p "按 Enter 關閉此提示（服務將繼續在背景運行）..." 