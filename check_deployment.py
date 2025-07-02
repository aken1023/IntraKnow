#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Zeabur Docker 部署檢查腳本
檢查所有必要的配置文件是否正確設置
"""

import os
import sys
from pathlib import Path

def print_status(message, status="info"):
    """打印狀態信息"""
    colors = {
        "info": "\033[94m",    # 藍色
        "success": "\033[92m", # 綠色
        "warning": "\033[93m", # 黃色
        "error": "\033[91m",   # 紅色
        "reset": "\033[0m"     # 重置
    }
    
    symbols = {
        "info": "ℹ️",
        "success": "✅",
        "warning": "⚠️",
        "error": "❌"
    }
    
    color = colors.get(status, colors["info"])
    symbol = symbols.get(status, symbols["info"])
    reset = colors["reset"]
    
    print(f"{color}{symbol} {message}{reset}")

def check_file_exists(file_path, description):
    """檢查文件是否存在"""
    if Path(file_path).exists():
        print_status(f"{description}: {file_path}", "success")
        return True
    else:
        print_status(f"{description} 缺失: {file_path}", "error")
        return False

def check_file_content(file_path, required_content, description):
    """檢查文件內容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            if all(item in content for item in required_content):
                print_status(f"{description} 內容正確", "success")
                return True
            else:
                missing = [item for item in required_content if item not in content]
                print_status(f"{description} 缺少內容: {missing}", "warning")
                return False
    except Exception as e:
        print_status(f"{description} 讀取錯誤: {e}", "error")
        return False

def main():
    """主檢查函數"""
    print_status("🚀 開始檢查 Zeabur Docker 部署配置", "info")
    print("=" * 60)
    
    all_checks_passed = True
    
    # 檢查核心配置文件
    print_status("📁 檢查核心配置文件", "info")
    
    required_files = [
        ("Dockerfile", "Docker 構建配置"),
        ("nginx.conf", "Nginx 代理配置"),
        ("supervisord.conf", "Supervisor 進程管理配置"),
        ("start.sh", "啟動腳本"),
        ("zeabur.toml", "Zeabur 部署配置"),
        ("package.json", "Node.js 依賴配置"),
        ("scripts/requirements-zeabur-fixed.txt", "Python 依賴配置")
    ]
    
    for file_path, description in required_files:
        if not check_file_exists(file_path, description):
            all_checks_passed = False
    
    print()
    
    # 檢查 Dockerfile 內容
    print_status("🐳 檢查 Dockerfile 配置", "info")
    dockerfile_content = [
        "FROM node:18-slim as frontend-builder",
        "FROM python:3.11-slim",
        "nginx",
        "supervisor",
        "npm run build",
        "EXPOSE 80"
    ]
    if not check_file_content("Dockerfile", dockerfile_content, "Dockerfile"):
        all_checks_passed = False
    
    # 檢查 nginx.conf 內容
    print_status("🌐 檢查 Nginx 配置", "info")
    nginx_content = [
        "listen 80",
        "proxy_pass http://localhost:3000",
        "proxy_pass http://localhost:8000/api/",
        "proxy_pass http://localhost:8000/auth/",
        "/health"
    ]
    if not check_file_content("nginx.conf", nginx_content, "Nginx 配置"):
        all_checks_passed = False
    
    # 檢查 supervisord.conf 內容
    print_status("⚙️ 檢查 Supervisor 配置", "info")
    supervisor_content = [
        "[program:nginx]",
        "[program:backend]",
        "[program:frontend]",
        "python scripts/auth_api_server.py",
        "npm start"
    ]
    if not check_file_content("supervisord.conf", supervisor_content, "Supervisor 配置"):
        all_checks_passed = False
    
    # 檢查 zeabur.toml 內容
    print_status("☁️ 檢查 Zeabur 配置", "info")
    zeabur_content = [
        'type = "docker"',
        'dockerfile = "Dockerfile"',
        'port = 80',
        'health_check = "/api/health"'
    ]
    if not check_file_content("zeabur.toml", zeabur_content, "Zeabur 配置"):
        all_checks_passed = False
    
    # 檢查 package.json 內容
    print_status("📦 檢查 package.json 配置", "info")
    package_content = [
        '"start": "next start -p 3000"',
        '"build": "next build"',
        '"next":'
    ]
    if not check_file_content("package.json", package_content, "package.json"):
        all_checks_passed = False
    
    # 檢查 start.sh 權限
    print_status("🔧 檢查啟動腳本", "info")
    start_sh_path = Path("start.sh")
    if start_sh_path.exists():
        if os.access(start_sh_path, os.X_OK):
            print_status("start.sh 有執行權限", "success")
        else:
            print_status("start.sh 缺少執行權限，運行: chmod +x start.sh", "warning")
    
    print()
    print("=" * 60)
    
    # 總結
    if all_checks_passed:
        print_status("🎉 所有檢查通過！準備部署到 Zeabur", "success")
        print()
        print_status("下一步操作:", "info")
        print("1. git add .")
        print("2. git commit -m 'Add Zeabur Docker deployment configuration'")
        print("3. git push")
        print("4. 在 Zeabur 控制台中部署")
        print()
        return True
    else:
        print_status("❌ 部分檢查未通過，請修復後再部署", "error")
        print()
        print_status("修復建議:", "info")
        print("1. 確保所有配置文件都已創建")
        print("2. 檢查文件內容是否正確")
        print("3. 重新運行此腳本驗證")
        print()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 