export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-foreground">404</h1>
        <p className="mt-4 text-xl text-muted-foreground">頁面未找到</p>
        <p className="mt-2 text-muted-foreground">您要查找的頁面可能已被刪除、更名或暫時不可用。</p>
        <a 
          href="/" 
          className="mt-6 inline-block rounded-md bg-primary px-4 py-2 text-primary-foreground hover:bg-primary/90"
        >
          返回首頁
        </a>
      </div>
    </div>
  )
} 