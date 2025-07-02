#!/usr/bin/env python
"""
創建默認用戶腳本
用於解決登入問題
"""

import sys
import os
from pathlib import Path

# 添加專案根目錄到路徑
current_dir = Path(__file__).parent
parent_dir = current_dir.parent
sys.path.insert(0, str(parent_dir))

from scripts.database import create_tables, get_db, create_user, get_user_by_username
from sqlalchemy.orm import Session

def create_default_users():
    """創建默認用戶"""
    print("🔧 創建默認用戶...")
    
    # 確保數據庫表已創建
    create_tables()
    
    # 獲取數據庫會話
    db_gen = get_db()
    db = next(db_gen)
    
    try:
        # 默認用戶列表
        default_users = [
            {
                "username": "admin",
                "email": "admin@example.com",
                "password": "admin123",
                "full_name": "系統管理員"
            },
            {
                "username": "test",
                "email": "test@example.com", 
                "password": "test123",
                "full_name": "測試用戶"
            },
            {
                "username": "demo",
                "email": "demo@example.com",
                "password": "demo123", 
                "full_name": "演示用戶"
            }
        ]
        
        created_users = []
        
        for user_info in default_users:
            # 檢查用戶是否已存在
            existing_user = get_user_by_username(db, user_info["username"])
            
            if existing_user:
                print(f"✅ 用戶 '{user_info['username']}' 已存在")
            else:
                # 創建用戶
                try:
                    new_user = create_user(
                        db=db,
                        username=user_info["username"],
                        email=user_info["email"],
                        password=user_info["password"],
                        full_name=user_info["full_name"]
                    )
                    created_users.append(user_info)
                    print(f"✅ 成功創建用戶 '{user_info['username']}'")
                except Exception as e:
                    print(f"❌ 創建用戶 '{user_info['username']}' 失敗: {e}")
        
        if created_users:
            print("\n🎉 成功創建的用戶:")
            for user in created_users:
                print(f"  用戶名: {user['username']}")
                print(f"  密碼: {user['password']}")
                print(f"  郵箱: {user['email']}")
                print("  ---")
        else:
            print("\n📝 可用的默認用戶:")
            for user in default_users:
                print(f"  用戶名: {user['username']}")
                print(f"  密碼: {user['password']}")
                print("  ---")
                
    except Exception as e:
        print(f"❌ 操作失敗: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_default_users() 