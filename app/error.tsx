'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // 可以在這裡記錄錯誤到錯誤報告服務
    console.error(error)
  }, [error])

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-destructive">500</h1>
        <p className="mt-4 text-xl text-muted-foreground">發生錯誤</p>
        <p className="mt-2 text-muted-foreground">抱歉，系統遇到了問題。請稍後再試。</p>
        <div className="mt-6 space-x-4">
          <button
            onClick={reset}
            className="inline-block rounded-md bg-primary px-4 py-2 text-primary-foreground hover:bg-primary/90"
          >
            重試
          </button>
          <a 
            href="/" 
            className="inline-block rounded-md border border-input bg-background px-4 py-2 text-foreground hover:bg-accent"
          >
            返回首頁
          </a>
        </div>
      </div>
    </div>
  )
} 