#!/bin/bash

# 企業知識庫系統安裝腳本

echo "🚀 開始安裝企業知識庫系統..."

# 檢查 Python 版本
python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
if [[ $(echo "$python_version >= 3.10" | bc -l) -eq 0 ]]; then
    echo "⚠️ 警告: 推薦使用 Python 3.10 或更高版本，但會嘗試繼續安裝"
else
    echo "✅ Python 版本檢查通過: $python_version"
fi

# 創建虛擬環境
echo "📦 創建虛擬環境..."
python3 -m venv venv
source venv/bin/activate

# 安裝依賴
echo "📥 安裝 Python 依賴..."
pip install --upgrade pip
pip install -r scripts/requirements.txt

# 創建必要目錄
echo "📁 創建目錄結構..."
mkdir -p documents faiss_index logs

# 設置環境變數
echo "🔑 設置環境變數..."
if [ ! -f ".env" ]; then
    cat > .env << EOL
# 環境變數配置

# DeepSeek API 密鑰
DEEPSEEK_API_KEY=sk-888548c4041b4699b8bcf331f391b73a

# 系統配置
MODEL_NAME=deepseek-chat
EMBEDDING_MODEL=BAAI/bge-base-zh
EOL
    echo "✅ 創建 .env 文件"
else
    echo "✅ .env 文件已存在"
fi

# 下載並安裝 Ollama (可選)
echo "🤖 安裝 Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh
    echo "✅ Ollama 安裝完成"
else
    echo "✅ Ollama 已安裝"
fi

# 下載模型
echo "📥 下載 LLM 模型..."
ollama pull mistral

# 初始化知識庫
echo "🔧 初始化知識庫..."
python scripts/setup_knowledge_base.py

echo "🎉 安裝完成！"
echo ""
echo "啟動服務："
echo "1. 啟動 API 服務: python scripts/api_server.py"
echo "2. 或使用 Docker: docker-compose up -d"
echo ""
echo "訪問地址："
echo "- API 文檔: http://localhost:8000/docs"
echo "- 系統狀態: http://localhost:8000/status"
