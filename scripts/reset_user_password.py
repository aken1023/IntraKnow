#!/usr/bin/env python
"""
重置用戶密碼腳本
用於解決登入問題
"""

import sys
import os
from pathlib import Path

# 添加專案根目錄到路徑
current_dir = Path(__file__).parent
parent_dir = current_dir.parent
sys.path.insert(0, str(parent_dir))

from scripts.database import (
    create_tables, get_db, get_user_by_username, 
    update_user_password, get_password_hash
)
from sqlalchemy.orm import Session

def list_users():
    """列出所有用戶"""
    print("📋 現有用戶列表:")
    
    db_gen = get_db()
    db = next(db_gen)
    
    try:
        from scripts.database import User
        users = db.query(User).all()
        
        if not users:
            print("  沒有找到任何用戶")
        else:
            for user in users:
                print(f"  ID: {user.id}")
                print(f"  用戶名: {user.username}")
                print(f"  郵箱: {user.email}")
                print(f"  全名: {user.full_name or '未設置'}")
                print(f"  創建時間: {user.created_at}")
                print("  ---")
                
    except Exception as e:
        print(f"❌ 獲取用戶列表失敗: {e}")
    finally:
        db.close()

def reset_password(username: str, new_password: str):
    """重置用戶密碼"""
    print(f"🔧 重置用戶 '{username}' 的密碼...")
    
    db_gen = get_db()
    db = next(db_gen)
    
    try:
        # 查找用戶
        user = get_user_by_username(db, username)
        
        if not user:
            print(f"❌ 用戶 '{username}' 不存在")
            return False
            
        # 更新密碼
        success = update_user_password(db, user.id, new_password)
        
        if success:
            print(f"✅ 用戶 '{username}' 密碼重置成功")
            print(f"   新密碼: {new_password}")
            return True
        else:
            print(f"❌ 密碼重置失敗")
            return False
            
    except Exception as e:
        print(f"❌ 重置密碼時發生錯誤: {e}")
        return False
    finally:
        db.close()

def main():
    """主函數"""
    if len(sys.argv) < 2:
        print("使用方法:")
        print("  python reset_user_password.py list                    # 列出所有用戶")
        print("  python reset_user_password.py reset <用戶名> <新密碼>  # 重置密碼")
        print("")
        print("例子:")
        print("  python reset_user_password.py list")
        print("  python reset_user_password.py reset admin newpassword123")
        return
    
    command = sys.argv[1]
    
    if command == "list":
        list_users()
    elif command == "reset":
        if len(sys.argv) != 4:
            print("❌ 重置密碼需要提供用戶名和新密碼")
            print("使用方法: python reset_user_password.py reset <用戶名> <新密碼>")
            return
        
        username = sys.argv[2]
        new_password = sys.argv[3]
        
        if len(new_password) < 6:
            print("❌ 密碼長度至少需要 6 個字符")
            return
            
        reset_password(username, new_password)
    else:
        print(f"❌ 未知命令: {command}")
        print("可用命令: list, reset")

if __name__ == "__main__":
    main() 