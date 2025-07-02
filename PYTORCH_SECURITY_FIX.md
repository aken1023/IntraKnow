# 🛡️ PyTorch 安全漏洞修復指南

## 🚨 問題說明
遇到 PyTorch 安全漏洞錯誤：
```
ValueError: Due to a serious vulnerability issue in `torch.load`, even with `weights_only=True`, we now require users to upgrade torch to at least v2.6 in order to use the function.
```

**漏洞編號**: CVE-2025-32434
**影響版本**: PyTorch < 2.6.0
**修復方法**: 升級到 PyTorch >= 2.6.0

## ✅ 已修復的內容

### 1. 更新依賴版本
修改 `scripts/requirements-minimal.txt`：
```bash
# PyTorch (安全版本，修復 CVE-2025-32434)
torch>=2.6.0
transformers>=4.40.0
sentence-transformers>=2.5.0
safetensors>=0.4.0
```

### 2. 移除硬編碼版本
- 從 Dockerfile 中移除 `torch==2.1.0+cpu`
- 使用 requirements 文件中的安全版本

### 3. 使用 safetensors
- 添加 safetensors 依賴避免不安全的 torch.load
- 新版本 transformers 優先使用 safetensors 格式

## 🚀 立即部署修復

### 方案一：使用輕量化版本（推薦）
```bash
# 切換到修復後的輕量版本
mv Dockerfile Dockerfile.debug
mv Dockerfile.lightweight Dockerfile

# 提交並部署
git add .
git commit -m "Fix PyTorch security vulnerability CVE-2025-32434"
git push origin main
```

### 方案二：使用完整版本
```bash
# 直接使用修復後的完整版本
git add .
git commit -m "Fix PyTorch security vulnerability in full Dockerfile"
git push origin main
```

## 📋 環境變數配置（無需更改）
你的環境變數配置是正確的，只需添加一個變數（可選）：

```bash
# 強制使用 safetensors（可選）
SAFETENSORS_FAST_LOAD=1
```

## 🔍 驗證修復

部署後檢查：

1. **檢查 PyTorch 版本**：
   ```
   https://your-app.zeabur.app/api/health
   ```

2. **檢查嵌入模型載入**：
   應該看到類似日誌：
   ```
   INFO: 載入嵌入模型: BAAI/bge-base-zh-v1.5
   INFO: Using safetensors for model loading
   ```

3. **確認服務啟動**：
   - ✅ 前端可訪問
   - ✅ API 可響應
   - ✅ 無安全漏洞警告

## 🎯 預期改善

### 安全性
- ✅ 修復 CVE-2025-32434 漏洞
- ✅ 使用 safetensors 安全加載
- ✅ 最新版本的 transformers

### 性能
- ✅ 更快的模型載入（safetensors）
- ✅ 更好的記憶體效率
- ✅ 更穩定的推理過程

### 兼容性
- ✅ 支援最新的 Hugging Face 模型
- ✅ 更好的錯誤處理
- ✅ 向後兼容現有功能

## 🔧 如果仍有問題

### 1. 記憶體不足
如果遇到記憶體問題，可以：
```bash
# 在環境變數中添加
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
```

### 2. 模型下載失敗
如果網絡問題導致模型下載失敗：
```bash
# 使用鏡像站點
HF_ENDPOINT=https://hf-mirror.com
```

### 3. 啟動超時
增加健康檢查時間：
```bash
# 在 Zeabur 中設置更長的啟動超時
STARTUP_TIMEOUT=180
```

## 📊 修復進度

- [x] 識別安全漏洞
- [x] 更新依賴版本
- [x] 修改 Dockerfile
- [x] 測試本地構建
- [x] 準備部署文件
- [ ] 部署到 Zeabur
- [ ] 驗證修復效果

---
**修復時間**: 2025-01-02  
**狀態**: 🛡️ 安全漏洞已修復  
**建議**: 立即部署輕量化版本 