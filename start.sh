#!/bin/bash
set -e

echo "🚀 啟動 IntraKnow 企業知識庫系統"
echo "📦 檢查環境..."

# 檢查並創建必要目錄
mkdir -p user_documents user_indexes logs

# 檢查 Python 和 Node.js 是否可用
echo "🐍 Python 版本: $(python --version)"
echo "📦 Node.js 版本: $(node --version)"

# 初始化數據庫（如果存在初始化腳本）
if [ -f "scripts/setup_knowledge_base.py" ]; then
    echo "🗄️ 初始化數據庫..."
    python scripts/setup_knowledge_base.py
fi

# 檢查端口可用性
echo "🔍 檢查服務端口..."
if netstat -tuln | grep :80 > /dev/null; then
    echo "⚠️ 端口 80 已被使用"
fi

if netstat -tuln | grep :8000 > /dev/null; then
    echo "⚠️ 端口 8000 已被使用"
fi

if netstat -tuln | grep :3000 > /dev/null; then
    echo "⚠️ 端口 3000 已被使用"
fi

echo "✅ 環境準備完成，啟動服務..."

# 清理可能的舊進程
pkill -f "nginx" || true
pkill -f "python scripts/auth_api_server.py" || true
pkill -f "npm start" || true

# 等待一秒讓端口釋放
sleep 1

# 啟動 Supervisor
echo "🔄 啟動 Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf 