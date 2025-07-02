#!/usr/bin/env python
"""
IntraKnow 企業知識庫系統 - 統一啟動器
一鍵啟動前端和後端服務
"""

import os
import sys
import time
import threading
import subprocess
import platform
import signal
import logging
from pathlib import Path
from datetime import datetime

# 設置日誌
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)

# 創建日誌記錄器
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / "startup.log", encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("StartupManager")

# 顏色編碼
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# 全局進程列表
processes = []

def print_banner():
    """顯示啟動橫幅"""
    banner = f"""
{Colors.BLUE}{Colors.BOLD}╔══════════════════════════════════════════════════════════╗
║                                                          ║
║  {Colors.GREEN}IntraKnow 企業知識庫系統{Colors.BLUE}                                ║
║                                                          ║
║  {Colors.YELLOW}前後端一鍵啟動器{Colors.BLUE}                                      ║
║                                                          ║
║  {Colors.YELLOW}版本: 2.0.0 | 時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.BLUE}               ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝{Colors.ENDC}
"""
    print(banner)
    logger.info("IntraKnow 系統啟動器已啟動")

def check_requirements():
    """檢查系統需求"""
    logger.info("檢查系統需求...")
    
    # 檢查 Python 版本
    python_version = sys.version_info
    if python_version.major < 3 or (python_version.major == 3 and python_version.minor < 10):
        logger.warning(f"推薦使用 Python 3.10+，當前版本: {sys.version.split()[0]}")
    logger.info(f"Python 版本: {sys.version.split()[0]}")
    
    # 檢查 Node.js
    try:
        result = subprocess.run(["node", "--version"], capture_output=True, text=True, check=True)
        node_version = result.stdout.strip()
        logger.info(f"Node.js 版本: {node_version}")
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error("未找到 Node.js，請安裝 Node.js 和 npm")
        return False
    
    # 檢查必要目錄
    required_dirs = ["user_documents", "user_indexes", "logs"]
    for dir_name in required_dirs:
        dir_path = Path(dir_name)
        if not dir_path.exists():
            logger.warning(f"創建缺失目錄: {dir_name}")
            dir_path.mkdir(exist_ok=True)
    
    # 檢查環境變量文件
    if not Path(".env").exists():
        logger.warning("創建默認 .env 配置文件")
        with open(".env", "w", encoding='utf-8') as f:
            f.write("""# IntraKnow 環境變數配置
# DeepSeek API 密鑰 (請替換為您的真實密鑰)
DEEPSEEK_API_KEY=sk-your-api-key-here

# 系統配置
MODEL_NAME=deepseek-chat
EMBEDDING_MODEL=BAAI/bge-base-zh

# 數據庫配置
DATABASE_URL=sqlite:///./knowledge_base.db

# 安全配置 (請在生產環境中更改)
SECRET_KEY=your-secret-key-change-this-in-production

# 日誌配置
LOG_LEVEL=INFO
""")
        print(f"{Colors.YELLOW}[警告] 已創建默認 .env 文件，請編輯並設置您的 API 密鑰{Colors.ENDC}")
    
    return True

def setup_python_environment():
    """設置 Python 環境"""
    logger.info("設置 Python 環境...")
    
    # 檢查虛擬環境
    venv_path = Path("venv")
    if platform.system() == "Windows":
        activate_script = venv_path / "Scripts" / "activate.bat"
        pip_path = venv_path / "Scripts" / "pip.exe"
        python_path = venv_path / "Scripts" / "python.exe"
    else:
        activate_script = venv_path / "bin" / "activate"
        pip_path = venv_path / "bin" / "pip"
        python_path = venv_path / "bin" / "python"
    
    # 創建虛擬環境（如果不存在）
    if not activate_script.exists():
        logger.info("創建 Python 虛擬環境...")
        try:
            subprocess.run([sys.executable, "-m", "venv", "venv"], check=True)
            logger.info("虛擬環境創建成功")
        except subprocess.CalledProcessError as e:
            logger.error(f"創建虛擬環境失敗: {e}")
            return None
    
    # 安裝/更新依賴
    logger.info("安裝 Python 依賴...")
    try:
        # 升級 pip
        subprocess.run([str(pip_path), "install", "--upgrade", "pip"], 
                      check=True, capture_output=True)
        
        # 根據操作系統選擇合適的 requirements 文件
        if platform.system() == "Windows":
            requirements_file = "scripts/requirements-windows.txt"
            logger.info("使用 Windows 相容版本的依賴文件")
        else:
            requirements_file = "scripts/requirements.txt"
            logger.info("使用標準版本的依賴文件")
        
        # 安裝依賴
        subprocess.run([str(pip_path), "install", "-r", requirements_file], 
                      check=True, capture_output=True)
        
        logger.info("Python 依賴安裝完成")
        return str(python_path)
    except subprocess.CalledProcessError as e:
        logger.error(f"安裝 Python 依賴失敗: {e}")
        return None

def setup_frontend_environment():
    """設置前端環境"""
    logger.info("設置前端環境...")
    
    # 檢查並安裝 Node.js 依賴
    if not Path("node_modules").exists():
        logger.info("安裝 Node.js 依賴...")
        try:
            subprocess.run(["npm", "install"], check=True, capture_output=True)
            logger.info("Node.js 依賴安裝完成")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"安裝 Node.js 依賴失敗: {e}")
            return False
    else:
        logger.info("Node.js 依賴已存在")
        return True

def start_backend(python_path):
    """啟動後端服務"""
    logger.info("啟動後端 API 服務...")
    
    try:
        # 啟動認證 API 服務器
        api_process = subprocess.Popen(
            [python_path, "scripts/auth_api_server.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(api_process)
        
        # 後端輸出監控線程
        def monitor_backend():
            try:
                for line in api_process.stdout:
                    if line.strip():
                        print(f"{Colors.GREEN}[API] {line.strip()}{Colors.ENDC}")
                        logger.info(f"Backend: {line.strip()}")
            except Exception as e:
                logger.error(f"監控後端輸出時發生錯誤: {e}")
        
        backend_thread = threading.Thread(target=monitor_backend, daemon=True)
        backend_thread.start()
        
        # 等待後端啟動
        logger.info("等待後端服務啟動...")
        time.sleep(5)
        
        # 檢查後端是否正常啟動
        if api_process.poll() is None:
            logger.info("後端服務啟動成功")
            print(f"{Colors.GREEN}✓ 後端 API 服務已啟動 (PID: {api_process.pid}){Colors.ENDC}")
            return api_process
        else:
            logger.error("後端服務啟動失敗")
            return None
            
    except Exception as e:
        logger.error(f"啟動後端服務時發生錯誤: {e}")
        return None

def start_frontend():
    """啟動前端服務"""
    logger.info("啟動前端 Next.js 應用...")
    
    try:
        # 設置環境變量
        env = os.environ.copy()
        env["NEXT_PUBLIC_API_URL"] = "http://localhost:8000"
        
        # 啟動前端
        frontend_process = subprocess.Popen(
            ["npm", "run", "dev"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(frontend_process)
        
        # 前端輸出監控線程
        def monitor_frontend():
            try:
                for line in frontend_process.stdout:
                    if line.strip():
                        print(f"{Colors.BLUE}[Next.js] {line.strip()}{Colors.ENDC}")
                        if "ready" in line.lower() or "local:" in line.lower():
                            logger.info(f"Frontend: {line.strip()}")
            except Exception as e:
                logger.error(f"監控前端輸出時發生錯誤: {e}")
        
        frontend_thread = threading.Thread(target=monitor_frontend, daemon=True)
        frontend_thread.start()
        
        # 等待前端啟動
        logger.info("等待前端服務啟動...")
        time.sleep(8)
        
        # 檢查前端是否正常啟動
        if frontend_process.poll() is None:
            logger.info("前端服務啟動成功")
            print(f"{Colors.BLUE}✓ 前端應用已啟動 (PID: {frontend_process.pid}){Colors.ENDC}")
            return frontend_process
        else:
            logger.error("前端服務啟動失敗")
            return None
            
    except Exception as e:
        logger.error(f"啟動前端服務時發生錯誤: {e}")
        return None

def cleanup_processes(signum=None, frame=None):
    """清理所有進程"""
    logger.info("正在關閉所有服務...")
    print(f"\n{Colors.YELLOW}[系統] 正在關閉服務...{Colors.ENDC}")
    
    for process in processes:
        try:
            if process.poll() is None:  # 進程仍在運行
                logger.info(f"終止進程 PID: {process.pid}")
                process.terminate()
                
                # 等待進程優雅退出
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    logger.warning(f"強制殺死進程 PID: {process.pid}")
                    process.kill()
                    
        except Exception as e:
            logger.error(f"清理進程時發生錯誤: {e}")
    
    processes.clear()
    logger.info("所有服務已關閉")
    print(f"{Colors.GREEN}✓ 所有服務已安全關閉{Colors.ENDC}")

def display_system_info():
    """顯示系統訊息"""
    print(f"\n{Colors.HEADER}=== 系統狀態 ==={Colors.ENDC}")
    print(f"{Colors.GREEN}✓ 後端 API: http://localhost:8000{Colors.ENDC}")
    print(f"{Colors.GREEN}✓ 前端應用: http://localhost:3000{Colors.ENDC}")
    print(f"{Colors.GREEN}✓ API 文檔: http://localhost:8000/docs{Colors.ENDC}")
    print(f"{Colors.YELLOW}✓ 日誌文件: logs/startup.log{Colors.ENDC}")
    print(f"\n{Colors.YELLOW}💡 測試帳號:{Colors.ENDC}")
    print(f"   - admin / admin123")
    print(f"   - test / test123")
    print(f"   - demo / demo123")
    print(f"\n{Colors.HEADER}按 Ctrl+C 停止所有服務{Colors.ENDC}")

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
            logger.error("系統需求檢查失敗")
            sys.exit(1)
        
        # 設置 Python 環境
        python_path = setup_python_environment()
        if not python_path:
            logger.error("Python 環境設置失敗")
            sys.exit(1)
        
        # 設置前端環境
        if not setup_frontend_environment():
            logger.error("前端環境設置失敗")
            sys.exit(1)
        
        print(f"\n{Colors.HEADER}=== 啟動服務 ==={Colors.ENDC}")
        
        # 啟動後端
        backend_process = start_backend(python_path)
        if not backend_process:
            logger.error("後端啟動失敗")
            sys.exit(1)
        
        # 啟動前端
        frontend_process = start_frontend()
        if not frontend_process:
            logger.error("前端啟動失敗")
            cleanup_processes()
            sys.exit(1)
        
        # 顯示系統信息
        display_system_info()
        
        # 主循環 - 監控服務狀態
        try:
            while True:
                # 檢查進程是否還在運行
                if backend_process.poll() is not None:
                    logger.error("後端服務意外退出")
                    break
                if frontend_process.poll() is not None:
                    logger.error("前端服務意外退出")
                    break
                
                time.sleep(5)
                
        except KeyboardInterrupt:
            logger.info("用戶中斷，開始關閉服務...")
        
    except Exception as e:
        logger.error(f"系統發生未預期的錯誤: {e}")
    finally:
        cleanup_processes()

if __name__ == "__main__":
    main() 