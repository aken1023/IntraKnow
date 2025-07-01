"""
LlamaIndex + FAISS + DeepSeek LLM 知識庫系統
企業級私有化部署方案
"""

import os
import logging
from pathlib import Path
from typing import List, Optional
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 配置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KnowledgeBaseSystem:
    """企業知識庫系統核心類"""
    
    def __init__(self, 
                 docs_folder: str = "documents",
                 index_path: str = "faiss_index",
                 embed_model_name: str = os.getenv("EMBEDDING_MODEL", "BAAI/bge-base-zh")):
        """
        初始化知識庫系統
        
        Args:
            docs_folder: 文檔存放目錄
            index_path: FAISS 索引存放路徑
            embed_model_name: 嵌入模型名稱
        """
        self.docs_folder = Path(docs_folder)
        self.index_path = Path(index_path)
        self.embed_model_name = embed_model_name
        
        # 創建必要目錄
        self.docs_folder.mkdir(exist_ok=True)
        self.index_path.mkdir(exist_ok=True)
        
        # 初始化嵌入模型
        logger.info(f"載入嵌入模型: {embed_model_name}")
        self.embed_model = SentenceTransformer(embed_model_name)
        
        # 初始化 FAISS 索引
        self.dimension = 768  # BGE 模型維度
        self.faiss_index = None
        self.documents = []
        self.doc_metadata = []
        
    def load_documents(self) -> List[str]:
        """載入文檔"""
        documents = []
        metadata = []
        
        for file_path in self.docs_folder.glob("**/*"):
            if file_path.is_file() and file_path.suffix in ['.txt', '.md']:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        documents.append(content)
                        metadata.append({
                            'filename': file_path.name,
                            'path': str(file_path),
                            'size': len(content)
                        })
                        logger.info(f"載入文檔: {file_path.name}")
                except Exception as e:
                    logger.error(f"載入文檔失敗 {file_path}: {e}")
        
        self.documents = documents
        self.doc_metadata = metadata
        return documents
    
    def build_index(self):
        """建立 FAISS 向量索引"""
        if not self.documents:
            logger.warning("沒有文檔可建立索引")
            return
        
        logger.info("開始建立向量索引...")
        
        # 生成文檔嵌入向量
        embeddings = self.embed_model.encode(self.documents)
        embeddings = np.array(embeddings).astype('float32')
        
        # 創建 FAISS 索引
        self.faiss_index = faiss.IndexFlatIP(self.dimension)  # 內積相似度
        self.faiss_index.add(embeddings)
        
        # 保存索引
        index_file = self.index_path / "faiss.index"
        faiss.write_index(self.faiss_index, str(index_file))
        
        logger.info(f"索引建立完成，包含 {len(self.documents)} 個文檔")
        
    def load_index(self):
        """載入已存在的索引"""
        index_file = self.index_path / "faiss.index"
        if index_file.exists():
            self.faiss_index = faiss.read_index(str(index_file))
            logger.info("載入現有索引成功")
            return True
        return False
    
    def search(self, query: str, top_k: int = 5) -> List[dict]:
        """搜索相關文檔"""
        if not self.faiss_index:
            logger.error("索引未建立")
            return []
        
        # 生成查詢向量
        query_embedding = self.embed_model.encode([query])
        query_embedding = np.array(query_embedding).astype('float32')
        
        # 搜索
        scores, indices = self.faiss_index.search(query_embedding, top_k)
        
        results = []
        for i, (score, idx) in enumerate(zip(scores[0], indices[0])):
            if idx < len(self.documents):
                results.append({
                    'rank': i + 1,
                    'score': float(score),
                    'content': self.documents[idx][:500] + "..." if len(self.documents[idx]) > 500 else self.documents[idx],
                    'metadata': self.doc_metadata[idx] if idx < len(self.doc_metadata) else {}
                })
        
        return results
    
    def query_with_llm(self, query: str, context_docs: List[str]) -> str:
        """結合檢索結果調用 DeepSeek LLM API"""
        # 構建提示詞
        context = "\n\n".join([f"文檔{i+1}: {doc}" for i, doc in enumerate(context_docs)])
        
        prompt = f"""基於以下文檔內容回答問題：

{context}

問題: {query}

請基於上述文檔內容提供準確、詳細的回答："""
        
        # 調用 DeepSeek API
        import requests
        
        try:
            # 從環境變數獲取 API 密鑰
            api_key = os.getenv("DEEPSEEK_API_KEY")
            if not api_key:
                logger.error("未設置 DEEPSEEK_API_KEY 環境變數")
                return "錯誤：未設置 DeepSeek API 密鑰"
                
            response = requests.post(
                "https://api.deepseek.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}"
                },
                json={
                    "model": os.getenv("MODEL_NAME", "deepseek-chat"),
                    "messages": [
                        {"role": "system", "content": "你是一個企業知識庫助手，負責基於檢索到的文檔回答用戶問題。"},
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.7
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]
            else:
                logger.error(f"API 調用失敗: {response.status_code} {response.text}")
                return f"API 調用失敗: {response.text}"
                
        except Exception as e:
            logger.error(f"LLM 調用錯誤: {e}")
            return f"基於檢索到的文檔，無法生成回答。錯誤: {str(e)}"

def main():
    """主函數 - 演示系統使用"""
    # 初始化系統
    kb_system = KnowledgeBaseSystem()
    
    # 創建示例文檔
    sample_docs = [
        ("ai_basics.txt", """
生成式人工智能（Generative AI）是一種能夠創建新內容的人工智能技術。
它可以生成文本、圖像、音頻、視頻等多種形式的內容。
主要技術包括：
1. 大型語言模型（LLM）
2. 擴散模型（Diffusion Models）
3. 生成對抗網絡（GAN）
4. 變分自編碼器（VAE）

企業應用場景：
- 內容創作和營銷
- 代碼生成和輔助開發
- 客戶服務自動化
- 文檔摘要和分析
        """),
        
        ("enterprise_ai.txt", """
企業級AI應用的最佳實踐：

1. 數據安全和隱私保護
   - 本地化部署
   - 數據加密
   - 訪問控制

2. 模型選擇和優化
   - 根據業務需求選擇合適模型
   - 模型微調和優化
   - 性能監控

3. 系統架構設計
   - 可擴展性
   - 高可用性
   - 容災備份

4. 成本控制
   - 資源優化
   - 批量處理
   - 緩存策略
        """),
        
        ("rag_system.txt", """
檢索增強生成（RAG）系統設計：

核心組件：
1. 文檔處理器 - 解析和分塊
2. 向量數據庫 - 存儲嵌入向量
3. 檢索器 - 相似度搜索
4. 生成器 - LLM 回答生成

技術選型：
- LlamaIndex: 文檔處理和索引
- FAISS: 高效向量搜索
- BGE: 中文嵌入模型
- Ollama: 本地LLM部署

優化策略：
- 文檔分塊優化
- 重排序（Re-ranking）
- 混合檢索
- 結果緩存
        """)
    ]
    
    # 創建示例文檔
    for filename, content in sample_docs:
        doc_path = kb_system.docs_folder / filename
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(content)
    
    # 載入文檔並建立索引
    kb_system.load_documents()
    kb_system.build_index()
    
    # 測試查詢
    test_queries = [
        "什麼是生成式AI？",
        "企業如何部署AI系統？",
        "RAG系統的核心組件有哪些？"
    ]
    
    for query in test_queries:
        print(f"\n{'='*50}")
        print(f"查詢: {query}")
        print(f"{'='*50}")
        
        # 檢索相關文檔
        search_results = kb_system.search(query, top_k=3)
        
        print("檢索結果:")
        for result in search_results:
            print(f"  排名 {result['rank']}: 相似度 {result['score']:.3f}")
            print(f"  內容: {result['content'][:100]}...")
            print()
        
        # 生成回答
        context_docs = [result['content'] for result in search_results[:2]]
        answer = kb_system.query_with_llm(query, context_docs)
        print(f"AI 回答:\n{answer}")

if __name__ == "__main__":
    main()
