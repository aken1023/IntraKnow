#!/usr/bin/env python
"""
日誌監控工具
用於實時監控和分析 logs/app.log
"""

import os
import time
import sys
from pathlib import Path
from datetime import datetime

def monitor_logs(log_file="logs/app.log", follow=True, lines=50):
    """監控日誌文件"""
    log_path = Path(log_file)
    
    if not log_path.exists():
        print(f"❌ 日誌文件不存在: {log_file}")
        print("💡 嘗試啟動服務器以生成日誌文件")
        return
    
    print(f"📋 監控日誌文件: {log_file}")
    print(f"⏰ 開始時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    if follow:
        # 實時跟踪模式
        print("🔍 實時監控模式 (按 Ctrl+C 退出)")
        try:
            with open(log_path, 'r', encoding='utf-8') as f:
                # 移動到文件末尾
                f.seek(0, 2)
                
                while True:
                    line = f.readline()
                    if line:
                        print(line.rstrip())
                    else:
                        time.sleep(0.1)
        except KeyboardInterrupt:
            print("\n📋 監控已停止")
    else:
        # 顯示最近的日誌
        print(f"📄 顯示最近 {lines} 行日誌:")
        try:
            with open(log_path, 'r', encoding='utf-8') as f:
                all_lines = f.readlines()
                recent_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines
                
                for line in recent_lines:
                    print(line.rstrip())
        except Exception as e:
            print(f"❌ 讀取日誌失敗: {e}")

def analyze_logs(log_file="logs/app.log"):
    """分析日誌文件中的錯誤和警告"""
    log_path = Path(log_file)
    
    if not log_path.exists():
        print(f"❌ 日誌文件不存在: {log_file}")
        return
    
    print(f"🔍 分析日誌文件: {log_file}")
    print("=" * 80)
    
    errors = []
    warnings = []
    info_count = 0
    
    try:
        with open(log_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                
                if " ERROR " in line or "❌" in line:
                    errors.append((line_num, line))
                elif " WARNING " in line or "⚠️" in line:
                    warnings.append((line_num, line))
                elif " INFO " in line:
                    info_count += 1
        
        # 輸出分析結果
        print(f"📊 日誌統計:")
        print(f"   INFO 消息: {info_count}")
        print(f"   WARNING 消息: {len(warnings)}")
        print(f"   ERROR 消息: {len(errors)}")
        print()
        
        if errors:
            print("❌ 錯誤消息:")
            for line_num, error in errors[-10:]:  # 顯示最近10個錯誤
                print(f"   第{line_num}行: {error}")
            print()
        
        if warnings:
            print("⚠️ 警告消息:")
            for line_num, warning in warnings[-5:]:  # 顯示最近5個警告
                print(f"   第{line_num}行: {warning}")
            print()
        
        if not errors and not warnings:
            print("✅ 沒有發現錯誤或警告")
    
    except Exception as e:
        print(f"❌ 分析日誌失敗: {e}")

def clear_logs(log_file="logs/app.log"):
    """清空日誌文件"""
    log_path = Path(log_file)
    
    if log_path.exists():
        try:
            with open(log_path, 'w', encoding='utf-8') as f:
                f.write("")
            print(f"✅ 日誌文件已清空: {log_file}")
        except Exception as e:
            print(f"❌ 清空日誌失敗: {e}")
    else:
        print(f"❌ 日誌文件不存在: {log_file}")

def main():
    """主函數"""
    if len(sys.argv) < 2:
        print("📋 日誌監控工具使用方法:")
        print("  python monitor_logs.py tail              # 顯示最近50行")
        print("  python monitor_logs.py follow            # 實時監控")
        print("  python monitor_logs.py analyze           # 分析錯誤和警告")
        print("  python monitor_logs.py clear             # 清空日誌")
        print("  python monitor_logs.py tail <行數>        # 顯示指定行數")
        print()
        print("例子:")
        print("  python monitor_logs.py tail")
        print("  python monitor_logs.py follow")
        print("  python monitor_logs.py analyze")
        return
    
    command = sys.argv[1]
    
    if command == "tail":
        lines = int(sys.argv[2]) if len(sys.argv) > 2 else 50
        monitor_logs(follow=False, lines=lines)
    elif command == "follow":
        monitor_logs(follow=True)
    elif command == "analyze":
        analyze_logs()
    elif command == "clear":
        clear_logs()
    else:
        print(f"❌ 未知命令: {command}")
        print("可用命令: tail, follow, analyze, clear")

if __name__ == "__main__":
    main() 