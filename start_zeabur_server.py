#!/usr/bin/env python
"""
Zeabur 專用服務器啟動腳本
解決 502 錯誤問題
包含完整的日誌記錄功能
"""

import os
import sys
import uvicorn
import logging
from pathlib import Path
from datetime import datetime

# 設置環境變量默認值
os.environ.setdefault("PORT", "8000")
os.environ.setdefault("SECRET_KEY", "zeabur-secret-key-change-this")
os.environ.setdefault("DATABASE_URL", "sqlite:///./knowledge_base.db")

# 添加專案根目錄到 Python 路徑
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

# 設置日誌記錄
def setup_logging():
    """設置詳細的日誌記錄"""
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    # 配置日誌格式
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # 設置多個日誌處理器
    handlers = [
        logging.FileHandler(log_dir / "app.log", encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
    
    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        handlers=handlers
    )
    
    return logging.getLogger(__name__)

def main():
    """主函數"""
    # 設置日誌記錄
    logger = setup_logging()
    
    logger.info("🚀 啟動 Zeabur 服務器...")
    logger.info(f"⏰ 啟動時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        # 記錄環境信息
        logger.info(f"🐍 Python 版本: {sys.version}")
        logger.info(f"📂 工作目錄: {os.getcwd()}")
        logger.info(f"🔧 環境變量:")
        for key in ["PORT", "PYTHON_VERSION", "SECRET_KEY", "DATABASE_URL"]:
            value = os.getenv(key, "未設置")
            if "KEY" in key and value != "未設置":
                value = "*" * len(value)  # 隱藏敏感信息
            logger.info(f"   {key}: {value}")
        
        # 確保必要目錄存在
        directories = ["user_documents", "user_indexes", "logs"]
        for dir_name in directories:
            os.makedirs(dir_name, exist_ok=True)
            logger.info(f"📁 創建/確認目錄: {dir_name}")
        
        # 導入並啟動 FastAPI 應用
        logger.info("📦 導入 FastAPI 應用...")
        from scripts.auth_api_server import app
        logger.info("✅ FastAPI 應用導入成功")
        
        # 獲取端口
        port = int(os.getenv("PORT", 8000))
        
        logger.info(f"📍 服務器將在端口 {port} 啟動")
        logger.info(f"🗄️ 數據庫 URL: {os.getenv('DATABASE_URL')}")
        logger.info(f"🌐 服務器地址: http://0.0.0.0:{port}")
        
        # 啟動服務器
        logger.info("🎯 啟動 Uvicorn 服務器...")
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=port,
            log_level="info",
            access_log=True
        )
        
    except ImportError as e:
        logger.error(f"❌ 導入錯誤: {e}")
        logger.error("💡 可能原因：依賴包未正確安裝或路徑問題")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ 服務器啟動失敗: {e}")
        logger.error(f"📊 錯誤類型: {type(e).__name__}")
        import traceback
        logger.error(f"📋 詳細錯誤信息:\n{traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main() 