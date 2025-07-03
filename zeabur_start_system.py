#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
IntraKnow 企業知識庫系統 - Zeabur 專用啟動器
同時啟動前後端服務
"""

import os
import sys
import time
import subprocess
import signal
import threading
from pathlib import Path

# 全局進程列表
processes = []

def print_banner():
    """顯示啟動橫幅"""
    print("=" * 60)
    print(" " * 15 + "IntraKnow 企業知識庫系統")
    print(" " * 18 + "Zeabur 雲端部署版本")
    print(" " * 20 + "版本 2.0.0")
    print("=" * 60)
    print()

def setup_environment():
    """設置 Zeabur 環境"""
    # 設置環境變量
    os.environ.setdefault("PORT", "3000")
    os.environ.setdefault("BACKEND_PORT", "8000") 
    os.environ.setdefault("NODE_ENV", "production")
    os.environ.setdefault("PYTHONUNBUFFERED", "1")
    
    # 獲取 Zeabur 提供的域名
    zeabur_domain = os.getenv("ZEABUR_DOMAIN", "intraknow.zeabur.app")
    api_url = f"https://{zeabur_domain}/api"
    
    # 設置前端 API URL
    os.environ["NEXT_PUBLIC_API_URL"] = api_url
    
    print(f"[環境] Zeabur 域名: {zeabur_domain}")
    print(f"[環境] API URL: {api_url}")
    
    return True

def setup_directories():
    """創建必要目錄"""
    dirs = ["user_documents", "user_indexes", "logs"]
    for dir_name in dirs:
        Path(dir_name).mkdir(exist_ok=True)
    print("[目錄] 必要目錄已準備完成")

def start_backend():
    """啟動後端服務"""
    print("[後端] 正在啟動 API 服務器...")
    try:
        # 設置後端環境變量
        env = os.environ.copy()
        env["PORT"] = os.getenv("BACKEND_PORT", "8000")
        env["HOST"] = "127.0.0.1"  # 內部通信
        
        # 啟動後端
        backend_process = subprocess.Popen(
            [sys.executable, "scripts/auth_api_server.py"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        processes.append(backend_process)
        
        # 監控後端輸出
        def monitor_backend():
            try:
                for line in backend_process.stdout:
                    if line.strip():
                        print(f"[API] {line.strip()}")
            except:
                pass
        
        backend_thread = threading.Thread(target=monitor_backend, daemon=True)
        backend_thread.start()
        
        # 等待後端啟動
        print("[後端] 等待 API 服務器啟動...")
        time.sleep(5)
        
        return backend_process
    except Exception as e:
        print(f"[錯誤] 啟動後端失敗: {e}")
        return None

def start_frontend():
    """啟動前端服務"""
    print("[前端] 正在啟動 Next.js 應用...")
    try:
        # 設置前端環境變量
        env = os.environ.copy()
        env["PORT"] = os.getenv("PORT", "3000")
        env["NODE_ENV"] = "production"
        
        # 首先構建前端
        print("[前端] 構建 Next.js 應用...")
        build_process = subprocess.run(
            ["npm", "run", "build"],
            env=env,
            capture_output=True,
            text=True
        )
        
        if build_process.returncode != 0:
            print(f"[錯誤] 前端構建失敗: {build_process.stderr}")
            return None
        
        print("[前端] 構建完成，啟動生產服務器...")
        
        # 啟動前端生產服務器
        frontend_process = subprocess.Popen(
            ["npm", "start"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        processes.append(frontend_process)
        
        # 監控前端輸出
        def monitor_frontend():
            try:
                for line in frontend_process.stdout:
                    if line.strip():
                        print(f"[Next.js] {line.strip()}")
            except:
                pass
        
        frontend_thread = threading.Thread(target=monitor_frontend, daemon=True)
        frontend_thread.start()
        
        return frontend_process
    except Exception as e:
        print(f"[錯誤] 啟動前端失敗: {e}")
        return None

def cleanup_processes(signum=None, frame=None):
    """清理所有進程"""
    print("\n[系統] 正在關閉所有服務...")
    
    for process in processes:
        try:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
        except Exception as e:
            print(f"[錯誤] 清理進程時發生錯誤: {e}")
    
    processes.clear()
    print("[成功] 所有服務已安全關閉")

def display_system_info():
    """顯示系統信息"""
    zeabur_domain = os.getenv("ZEABUR_DOMAIN", "intraknow.zeabur.app")
    
    print("\n" + "=" * 60)
    print(" " * 20 + "系統已成功啟動")
    print("=" * 60)
    print(f"應用網址: https://{zeabur_domain}")
    print(f"API 端點: https://{zeabur_domain}/api")
    print(f"API 文檔: https://{zeabur_domain}/docs")
    print()
    print("測試帳號:")
    print("  - admin / admin123")
    print("  - test / test123") 
    print("  - demo / demo123")
    print("=" * 60)

def wait_for_processes():
    """等待進程運行"""
    try:
        while True:
            # 檢查所有進程是否還在運行
            running = False
            for process in processes:
                if process.poll() is None:
                    running = True
                    break
            
            if not running:
                print("[警告] 所有服務已停止")
                break
                
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[接收] 收到停止信號")
    finally:
        cleanup_processes()

def main():
    """主函數"""
    try:
        # 設置信號處理
        signal.signal(signal.SIGINT, cleanup_processes)
        signal.signal(signal.SIGTERM, cleanup_processes)
        
        # 顯示橫幅
        print_banner()
        
        # 設置環境
        if not setup_environment():
            sys.exit(1)
        
        # 創建目錄
        setup_directories()
        
        # 啟動後端
        backend = start_backend()
        if not backend:
            print("[失敗] 後端啟動失敗")
            sys.exit(1)
        
        # 啟動前端
        frontend = start_frontend() 
        if not frontend:
            print("[失敗] 前端啟動失敗")
            cleanup_processes()
            sys.exit(1)
        
        # 顯示系統信息
        display_system_info()
        
        # 等待進程
        wait_for_processes()
        
    except Exception as e:
        print(f"[錯誤] 系統啟動失敗: {e}")
        cleanup_processes()
        sys.exit(1)

if __name__ == "__main__":
    main() 