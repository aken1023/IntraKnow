#!/usr/bin/env python
"""
Zeabur 專用服務器啟動腳本
解決 502 錯誤問題
"""

import os
import sys
import uvicorn
from pathlib import Path

# 設置環境變量默認值
os.environ.setdefault("PORT", "8000")
os.environ.setdefault("SECRET_KEY", "zeabur-secret-key-change-this")
os.environ.setdefault("DATABASE_URL", "sqlite:///./knowledge_base.db")

# 添加專案根目錄到 Python 路徑
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

def main():
    """主函數"""
    print("🚀 啟動 Zeabur 服務器...")
    
    try:
        # 確保必要目錄存在
        os.makedirs("user_documents", exist_ok=True)
        os.makedirs("user_indexes", exist_ok=True)
        os.makedirs("logs", exist_ok=True)
        
        # 導入並啟動 FastAPI 應用
        from scripts.auth_api_server import app
        
        # 獲取端口
        port = int(os.getenv("PORT", 8000))
        
        print(f"📍 服務器將在端口 {port} 啟動")
        print(f"🗄️ 數據庫 URL: {os.getenv('DATABASE_URL')}")
        
        # 啟動服務器
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=port,
            log_level="info",
            access_log=True
        )
        
    except Exception as e:
        print(f"❌ 服務器啟動失敗: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 