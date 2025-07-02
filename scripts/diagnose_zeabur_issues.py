#!/usr/bin/env python
"""
Zeabur 部署問題診斷腳本
用於排除 502 錯誤
"""

import os
import sys
import requests
from pathlib import Path

def check_environment_variables():
    """檢查環境變量"""
    print("🔍 檢查環境變量...")
    
    required_vars = [
        "PORT",
        "PYTHON_VERSION", 
        "DEEPSEEK_API_KEY",
        "SECRET_KEY"
    ]
    
    missing_vars = []
    
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {'*' * len(value) if 'KEY' in var else value}")
        else:
            missing_vars.append(var)
            print(f"❌ {var}: 未設置")
    
    if missing_vars:
        print(f"\n⚠️  缺少環境變量: {', '.join(missing_vars)}")
        return False
    return True

def check_dependencies():
    """檢查依賴文件"""
    print("\n📦 檢查依賴文件...")
    
    requirements_files = [
        "scripts/requirements.txt",
        "scripts/requirements-zeabur-fixed.txt",
        "scripts/requirements-minimal.txt"
    ]
    
    for req_file in requirements_files:
        if Path(req_file).exists():
            print(f"✅ 找到: {req_file}")
        else:
            print(f"❌ 缺少: {req_file}")

def check_database():
    """檢查數據庫"""
    print("\n🗄️  檢查數據庫...")
    
    try:
        # 添加專案根目錄到路徑
        current_dir = Path(__file__).parent
        parent_dir = current_dir.parent
        sys.path.insert(0, str(parent_dir))
        
        from scripts.database import create_tables, get_db
        
        # 嘗試創建表
        create_tables()
        print("✅ 數據庫表創建成功")
        
        # 嘗試連接數據庫
        db_gen = get_db()
        db = next(db_gen)
        db.close()
        print("✅ 數據庫連接正常")
        
        return True
        
    except Exception as e:
        print(f"❌ 數據庫錯誤: {e}")
        return False

def check_port_configuration():
    """檢查端口配置"""
    print("\n🔌 檢查端口配置...")
    
    port = os.getenv("PORT", "8000")
    print(f"📍 配置的端口: {port}")
    
    # 檢查端口是否為數字
    try:
        port_num = int(port)
        if 1 <= port_num <= 65535:
            print(f"✅ 端口 {port} 有效")
            return True
        else:
            print(f"❌ 端口 {port} 超出有效範圍")
            return False
    except ValueError:
        print(f"❌ 端口 {port} 不是有效數字")
        return False

def generate_zeabur_config():
    """生成 Zeabur 配置建議"""
    print("\n⚙️  生成 Zeabur 配置建議...")
    
    config = {
        "環境變量": {
            "PORT": "8000",
            "PYTHON_VERSION": "3.9",
            "SECRET_KEY": "your-secret-key-change-this-in-production",
            "DEEPSEEK_API_KEY": "你的DeepSeek API密鑰"
        },
        "啟動命令": "python scripts/auth_api_server.py",
        "依賴文件": "scripts/requirements-zeabur-fixed.txt"
    }
    
    print("建議的 Zeabur 配置:")
    for section, values in config.items():
        print(f"\n📋 {section}:")
        if isinstance(values, dict):
            for key, value in values.items():
                print(f"  {key}: {value}")
        else:
            print(f"  {values}")

def test_local_server():
    """測試本地服務器"""
    print("\n🧪 測試本地服務器...")
    
    try:
        # 嘗試導入並啟動服務器模塊
        sys.path.insert(0, str(Path(__file__).parent.parent))
        
        # 檢查是否可以導入主要模塊
        try:
            from scripts.auth_api_server import app
            print("✅ 成功導入 FastAPI 應用")
        except ImportError as e:
            print(f"❌ 導入 FastAPI 應用失敗: {e}")
            return False
            
        # 檢查是否可以導入數據庫模塊
        try:
            from scripts.database import create_tables
            print("✅ 成功導入數據庫模塊")
        except ImportError as e:
            print(f"❌ 導入數據庫模塊失敗: {e}")
            return False
            
        return True
        
    except Exception as e:
        print(f"❌ 測試本地服務器失敗: {e}")
        return False

def main():
    """主診斷函數"""
    print("🚀 開始 Zeabur 部署問題診斷...\n")
    
    issues = []
    
    # 檢查環境變量
    if not check_environment_variables():
        issues.append("環境變量缺失")
    
    # 檢查依賴
    check_dependencies()
    
    # 檢查數據庫
    if not check_database():
        issues.append("數據庫問題")
    
    # 檢查端口
    if not check_port_configuration():
        issues.append("端口配置問題")
    
    # 測試本地服務器
    if not test_local_server():
        issues.append("服務器模塊問題")
    
    # 生成配置建議
    generate_zeabur_config()
    
    # 總結
    print(f"\n📊 診斷總結:")
    if issues:
        print("❌ 發現問題:")
        for issue in issues:
            print(f"  - {issue}")
        print("\n🔧 建議解決步驟:")
        print("1. 在 Zeabur 控制台設置正確的環境變量")
        print("2. 確保使用正確的依賴文件 (requirements-zeabur-fixed.txt)")
        print("3. 檢查服務日誌以獲取詳細錯誤信息")
        print("4. 重新部署服務")
    else:
        print("✅ 本地配置看起來正常，問題可能在於 Zeabur 特定配置")
        print("建議檢查 Zeabur 服務日誌以獲取更多信息")

if __name__ == "__main__":
    main() 