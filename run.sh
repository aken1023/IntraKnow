#!/bin/bash

# LlamaIndex-FAISS 知識庫系統啟動腳本

echo "=== LlamaIndex-FAISS 知識庫系統啟動腳本 ==="
echo "正在啟動整合系統..."

# 檢查 Python
if ! command -v python3 &> /dev/null; then
    echo "錯誤: 未找到 Python。請安裝 Python 3.10 或更高版本。"
    exit 1
fi

# 確保腳本可執行
chmod +x run_all.py

# 執行主腳本
python3 run_all.py 