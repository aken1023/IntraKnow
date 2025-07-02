#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
IntraKnow 企業知識庫系統 - 最終整合啟動器
直接使用系統 Python，避免虛擬環境問題
"""

import os
import sys
import time
import subprocess
import signal
import threading
import webbrowser
from pathlib import Path

# 全局進程列表
processes = []


def print_banner():
    """顯示啟動橫幅"""
    print("=" * 60)
    print(" " * 15 + "IntraKnow 企業知識庫系統")
    print(" " * 18 + "前後端整合啟動器")
    print(" " * 20 + "版本 2.0.0")
    print("=" * 60)
    print()

def check_requirements():
    """檢查系統需求"""
    print("[檢查] 正在檢查系統需求...")
    
    # 檢查 Python 版本
    print(f"[Python] 版本: {sys.version.split()[0]}")
    
    # 檢查 Node.js
    try:
        result = subprocess.run(["node", "--version"],
                                capture_output=True, text=True, check=True)
        node_version = result.stdout.strip()
        print(f"[Node.js] 版本: {node_version}")
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("[錯誤] 未找到 Node.js，請安裝 Node.js 和 npm")
        return False
    
    print("[成功] 系統需求檢查通過")
    return True


def setup_directories():
    """創建必要目錄"""
    dirs = ["user_documents", "user_indexes", "logs"]
    for dir_name in dirs:
        Path(dir_name).mkdir(exist_ok=True)
    print("[目錄] 必要目錄已準備完成")

def check_frontend_dependencies():
    """檢查前端依賴"""
    if not Path("node_modules").exists():
        print("[安裝] 正在安裝前端依賴...")
        try:
            subprocess.run(["npm", "install"], check=True)
            print("[成功] 前端依賴安裝完成")
        except subprocess.CalledProcessError:
            print("[錯誤] 前端依賴安裝失敗")
            return False
    else:
        print("[前端] 依賴已存在")
    return True

def start_backend():
    """啟動後端服務"""
    print("[後端] 正在啟動 API 服務器...")
    try:
        # 啟動後端
        backend_process = subprocess.Popen(
            [sys.executable, "scripts/auth_api_server.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(backend_process)
        
        # 監控後端輸出的線程
        def monitor_backend():
            try:
                for line in backend_process.stdout:
                    if line.strip():
                        print(f"[API] {line.strip()}")
            except:
                pass
        
        backend_thread = threading.Thread(target=monitor_backend, daemon=True)
        backend_thread.start()
        
        return backend_process
    except Exception as e:
        print(f"[錯誤] 啟動後端失敗: {e}")
        return None

def start_frontend():
    """啟動前端服務"""
    print("[前端] 正在啟動 Next.js 應用...")
    try:
        # 設置環境變量
        env = os.environ.copy()
        env["NEXT_PUBLIC_API_URL"] = "http://localhost:8000"
        
        # 根據操作系統選擇命令
        import platform
        if platform.system() == "Windows":
            # Windows 下使用 npm.cmd
            cmd = ["npm.cmd", "run", "dev"]
        else:
            cmd = ["npm", "run", "dev"]
        
        # 啟動前端
        frontend_process = subprocess.Popen(
            cmd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(frontend_process)
        
        # 監控前端輸出的線程
        def monitor_frontend():
            try:
                for line in frontend_process.stdout:
                    if line.strip():
                        if "ready" in line.lower() or "local:" in line.lower():
                            print(f"[Next.js] {line.strip()}")
            except Exception:
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
            if process.poll() is None:  # 進程仍在運行
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
    print("\n" + "=" * 60)
    print(" " * 20 + "系統已成功啟動")
    print("=" * 60)
    print(f"前端應用: http://localhost:3000")
    print(f"後端 API: http://localhost:8000")
    print(f"API 文檔: http://localhost:8000/docs")
    print()
    print("測試帳號:")
    print("  - admin / admin123")
    print("  - test / test123")
    print("  - demo / demo123")
    print()
    print("日誌位置: logs/app.log")
    print("=" * 60)
    print()
    print("[提示] 按 Ctrl+C 停止所有服務")
    print("[提示] 稍候將自動打開瀏覽器...")

def main():
    """主函數"""
    try:
        # 設置信號處理
        signal.signal(signal.SIGINT, cleanup_processes)
        signal.signal(signal.SIGTERM, cleanup_processes)
        
        # 顯示橫幅
        print_banner()
        
        # 檢查系統需求
        if not check_requirements():
            print("\n[失敗] 系統需求檢查失敗，請安裝缺失的軟件")
            input("按 Enter 鍵退出...")
            sys.exit(1)
        
        # 設置目錄
        setup_directories()
        
        # 檢查前端依賴
        if not check_frontend_dependencies():
            print("\n[失敗] 前端環境設置失敗")
            input("按 Enter 鍵退出...")
            sys.exit(1)
        
        print("\n[啟動] 正在啟動服務...")
        
        # 啟動後端
        backend_process = start_backend()
        if not backend_process:
            print("[失敗] 後端啟動失敗")
            sys.exit(1)
        
        # 等待後端啟動
        print("[等待] 後端服務啟動中...")
        time.sleep(5)
        
        # 啟動前端
        frontend_process = start_frontend()
        if not frontend_process:
            print("[失敗] 前端啟動失敗")
            cleanup_processes()
            sys.exit(1)
        
        # 等待前端啟動
        print("[等待] 前端服務啟動中...")
        time.sleep(8)
        
        # 顯示系統信息
        display_system_info()
        
        # 自動打開瀏覽器
        try:
            time.sleep(2)
            webbrowser.open("http://localhost:3000")
            print("[瀏覽器] 已自動打開前端應用")
        except:
            print("[提示] 請手動打開瀏覽器訪問 http://localhost:3000")
        
        # 主循環 - 監控服務狀態
        try:
            while True:
                # 檢查進程是否還在運行
                if backend_process.poll() is not None:
                    print("\n[錯誤] 後端服務意外退出")
                    break
                if frontend_process.poll() is not None:
                    print("\n[錯誤] 前端服務意外退出")
                    break
                
                time.sleep(5)
                
        except KeyboardInterrupt:
            print("\n[信息] 用戶中斷服務...")
        
    except Exception as e:
        print(f"\n[錯誤] 系統發生未預期的錯誤: {e}")
    finally:
        cleanup_processes()
        print("\n按 Enter 鍵退出...")
        try:
            input()
        except:
            pass

if __name__ == "__main__":
    main() 