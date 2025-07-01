"use client"

import React, { useState, useEffect, useRef } from "react"
import { Upload, Search, FileText, MessageSquare, Loader2, Trash2, X, CheckCircle2, AlertCircle, RotateCcw, Download, Copy, Settings, Menu, Sun, Moon, Laptop } from "lucide-react"
import { useTheme } from "next-themes"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Label } from "@/components/ui/label"
import { Progress } from "@/components/ui/progress"
import { useAuth } from "@/components/auth/auth-context"
import { UserDropdown } from "@/components/user-dropdown"
import { cn } from "@/lib/utils"
import { useMediaQuery } from "@/hooks/use-media-query"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog"


// --- 介面定義 (保持不變) ---
const getApiBaseUrl = () => {
  if (process.env.NEXT_PUBLIC_DIRECT_API_URL) {
    return process.env.NEXT_PUBLIC_DIRECT_API_URL.replace(/\/$/, '')
  }
  return '/api'
}
const API_BASE_URL = getApiBaseUrl()

interface Document { id: number; filename: string; original_filename: string; file_size: number; upload_time: string; }
interface UploadingFile { file: File; progress: number; status: 'uploading' | 'success' | 'error'; error?: string; retryCount?: number; }
interface QueryResult { answer: string; sources?: Array<{ filename: string; content: string; similarity?: number; }>; query: string; timestamp: string; }
interface ConversationMessage { id: string; type: 'user' | 'assistant'; content: string; query?: string; sources?: Array<{ filename: string; content: string; similarity?: number; }>; timestamp: string; }

// --- 主儀表板元件 ---
export const KnowledgeBaseDashboard: React.FC = () => {
  const isDesktop = useMediaQuery("(min-width: 768px)")
  const [isSidebarOpen, setIsSidebarOpen] = useState(false)

  // 將所有 state 和函式傳遞給子元件
  const props = useDashboardState()

  return (
    <>
      {props.alert && (
        <div className="fixed top-5 right-5 z-50">
          <Alert variant={props.alert.type === 'error' ? 'destructive' : 'default'} className="max-w-sm">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>{props.alert.type === 'success' ? '成功' : '錯誤'}</AlertTitle>
            <AlertDescription>{props.alert.message}</AlertDescription>
          </Alert>
        </div>
      )}
      {isDesktop ? (
        <div className="grid min-h-screen w-full md:grid-cols-[280px_1fr]">
          <Sidebar {...props} />
          <MainContent {...props} />
        </div>
      ) : (
        <div className="flex min-h-screen w-full flex-col">
          <header className="sticky top-0 z-10 flex h-16 items-center gap-4 border-b bg-background/80 backdrop-blur-sm px-4 md:px-6">
            <Sheet open={isSidebarOpen} onOpenChange={setIsSidebarOpen}>
              <SheetTrigger asChild>
                <Button variant="outline" size="icon" className="shrink-0">
                  <Menu className="h-5 w-5" />
                  <span className="sr-only">Toggle navigation menu</span>
                </Button>
              </SheetTrigger>
              <SheetContent side="left" className="flex flex-col p-0">
                <Sidebar {...props} isMobile={true} onLinkClick={() => setIsSidebarOpen(false)} />
              </SheetContent>
            </Sheet>
            <div className="flex-1">
              <h1 className="font-semibold text-lg">知識庫</h1>
            </div>
            <UserDropdown />
          </header>
          <MainContent {...props} isMobile={true} />
        </div>
      )}
    </>
  )
}

// --- 側邊欄元件 ---
const Sidebar = ({ user, activeTab, setActiveTab, uploadedFiles, isMobile, onLinkClick }: any) => {
  const NavLink = ({ tabName, icon, label }: any) => (
    <button
      onClick={() => { setActiveTab(tabName); onLinkClick?.(); }}
      className={cn(
        "flex items-center gap-3 rounded-lg px-3 py-2 text-muted-foreground transition-all hover:text-primary",
        { "bg-muted text-primary": activeTab === tabName }
      )}
    >
      {icon}
      {label}
    </button>
  )

  return (
    <aside className={cn("flex-col border-r bg-background/95", isMobile ? "flex h-full" : "hidden md:flex")}>
      <div className="flex h-16 items-center border-b px-6">
        <h1 className="text-xl font-serif font-bold text-primary">知識庫管理機器人</h1>
      </div>
      <nav className="flex-1 grid items-start p-4 text-sm font-medium">
        <NavLink tabName="query" icon={<MessageSquare className="h-4 w-4" />} label="智能問答" />
        <NavLink tabName="upload" icon={<Upload className="h-4 w-4" />} label={`文檔管理 (${uploadedFiles.length})`} />
        <NavLink tabName="settings" icon={<Settings className="h-4 w-4" />} label="系統設定" />
      </nav>
      {!isMobile && (
        <div className="mt-auto p-4 border-t">
          <div className="flex items-center gap-3">
            <UserDropdown />
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold truncate">{user?.username}</p>
              <p className="text-xs text-muted-foreground truncate">{user?.email}</p>
            </div>
          </div>
        </div>
      )}
    </aside>
  )
}

// --- 主內容區元件 ---
const MainContent = ({ activeTab, ...props }: any) => {
  return (
    <main className="flex flex-1 flex-col gap-4 p-4 md:gap-8 md:p-6 bg-muted/40">
      {activeTab === 'query' && <ChatPanel {...props} />}
      {activeTab === 'upload' && <DocumentPanel {...props} />}
      {activeTab === 'settings' && <SettingsPanel {...props} />}
    </main>
  )
}

// --- 聊天面板 ---
const ChatPanel = ({ conversation, handleQuery, query, setQuery, isLoading, conversationEndRef, clearConversation, exportConversation }: any) => (
  <div className="flex flex-col h-full">
    <div className="flex items-center justify-between pb-4 border-b">
      <div>
        <h2 className="text-2xl font-serif font-bold">智能問答</h2>
        <p className="text-muted-foreground">與您的知識庫進行深度對話</p>
      </div>
      {conversation.length > 0 && (
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={exportConversation}><Download className="w-4 h-4 mr-2" />匯出</Button>
          <Button variant="destructive" size="sm" onClick={clearConversation}><Trash2 className="w-4 h-4 mr-2" />清除</Button>
        </div>
      )}
    </div>

    <div className="flex-1 overflow-y-auto py-6 space-y-6 pr-2">
      {conversation.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-full text-center text-muted-foreground">
          <MessageSquare className="w-16 h-16 mb-4 text-primary/20" />
          <h3 className="text-xl font-semibold">開啟一段對話</h3>
          <p>在這裡輸入您的問題，開始探索知識。</p>
        </div>
      ) : (
        conversation.map((message: ConversationMessage) => (
          <div key={message.id} className={cn("flex items-start gap-4", { "justify-end": message.type === 'user' })}>
            {message.type === 'assistant' && <div className="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0">A</div>}
            <div className={cn("max-w-[85%] p-4 rounded-xl", {
              "bg-primary text-primary-foreground": message.type === 'user',
              "bg-background border": message.type === 'assistant'
            })}>
              <p className="whitespace-pre-wrap">{message.content}</p>
              {message.type === 'assistant' && message.sources && message.sources.length > 0 && (
                <div className="mt-4 pt-3 border-t border-border/50">
                  <h4 className="text-xs font-semibold mb-2">參考來源:</h4>
                  <div className="space-y-2">
                    {message.sources.map((source: any, index: number) => (
                      <div key={index} className="p-2 bg-muted/50 rounded-md text-xs">
                        <p className="font-semibold truncate">{source.filename}</p>
                        <p className="text-muted-foreground line-clamp-2">{source.content}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            {message.type === 'user' && <div className="w-8 h-8 rounded-full bg-secondary text-secondary-foreground flex items-center justify-center shrink-0">U</div>}
          </div>
        ))
      )}
      {isLoading && <div className="text-center text-muted-foreground">思考中... <Loader2 className="inline w-4 h-4 animate-spin" /></div>}
      <div ref={conversationEndRef} />
    </div>

    <div className="mt-auto pt-4 border-t">
      <form onSubmit={(e) => { e.preventDefault(); handleQuery(); }} className="relative">
        <Textarea
          placeholder="輸入您的問題... (Shift + Enter 換行)"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          rows={3}
          disabled={isLoading}
          className="pr-20 resize-none"
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              handleQuery();
            }
          }}
        />
        <Button type="submit" size="icon" className="absolute right-3 bottom-3" disabled={isLoading || !query.trim()}>
          <Search className="w-4 h-4" />
        </Button>
      </form>
    </div>
  </div>
)

// --- 文檔面板 ---
const DocumentPanel = ({ uploadedFiles, handleFiles, handleDeleteDocument, authLoading, uploadingFiles, retryUpload, removeUploadingFile, formatFileSize, formatDate }: any) => {
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [isDragOver, setIsDragOver] = useState(false)

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-serif font-bold">文檔管理</h2>
        <p className="text-muted-foreground">上傳、查看和管理您的知識庫文件。</p>
      </div>

      {/* 上傳區域 */}
      <div 
        onDrop={(e) => { e.preventDefault(); setIsDragOver(false); handleFiles(e.dataTransfer.files); }}
        onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
        onDragLeave={() => setIsDragOver(false)}
        className={cn("flex flex-col items-center justify-center p-12 border-2 border-dashed rounded-xl transition-colors", {
          "border-primary bg-primary/10": isDragOver
        })}
      >
        <Upload className="w-12 h-12 mb-4 text-muted-foreground" />
        <h3 className="text-lg font-medium">拖曳文件到此處</h3>
        <p className="text-muted-foreground">或</p>
        <Button variant="link" onClick={() => fileInputRef.current?.click()}>
          點擊選擇文件
        </Button>
        <p className="text-xs text-muted-foreground mt-2">支持 TXT, MD, PDF、DOCX. 最大 500MB.</p>
        <Input ref={fileInputRef} type="file" multiple onChange={(e) => handleFiles(e.target.files)} className="hidden" />
      </div>

      {/* 上傳進度 */}
      {uploadingFiles.length > 0 && (
        <div className="space-y-4">
          <h3 className="font-semibold">上傳中</h3>
          {uploadingFiles.map((f: UploadingFile, i: number) => (
            <div key={i} className="p-3 border rounded-lg flex items-center gap-4">
              <div className="shrink-0">
                {f.status === 'uploading' && <Loader2 className="w-5 h-5 animate-spin text-primary" />}
                {f.status === 'success' && <CheckCircle2 className="w-5 h-5 text-green-500" />}
                {f.status === 'error' && <AlertCircle className="w-5 h-5 text-destructive" />}
              </div>
              <div className="flex-1">
                <p className="font-medium truncate">{f.file.name}</p>
                <Progress value={f.progress} className="h-2 mt-1" />
                {f.error && <p className="text-xs text-destructive mt-1">{f.error}</p>}
              </div>
              {f.status === 'error' && <Button size="sm" variant="outline" onClick={() => retryUpload(f.file)}>重試</Button>}
              <Button size="icon" variant="ghost" onClick={() => removeUploadingFile(f.file)}><X className="w-4 h-4" /></Button>
            </div>
          ))}
        </div>
      )}

      {/* 文件列表 */}
      <div className="space-y-4">
        <h3 className="font-semibold">我的文檔 ({uploadedFiles.length})</h3>
        {authLoading ? (
          <p className="text-muted-foreground">載入中...</p>
        ) : uploadedFiles.length > 0 ? (
          <div className="border rounded-lg">
            <div className="grid grid-cols-[1fr_100px_100px_40px] gap-4 p-3 font-medium text-muted-foreground border-b">
              <div>文件名</div>
              <div>大小</div>
              <div>上傳日期</div>
              <div></div>
            </div>
            <div className="max-h-[40vh] overflow-y-auto">
              {uploadedFiles.map((file: Document) => (
                <div key={file.id} className="grid grid-cols-[1fr_100px_100px_40px] gap-4 p-3 items-center border-b last:border-none">
                  <p className="truncate font-medium flex items-center gap-2"><FileText className="w-4 h-4 shrink-0" /> {file.original_filename}</p>
                  <p className="text-sm text-muted-foreground">{formatFileSize(file.file_size)}</p>
                  <p className="text-sm text-muted-foreground">{formatDate(file.upload_time)}</p>
                  <Button variant="ghost" size="icon" onClick={() => handleDeleteDocument(file.id)}><Trash2 className="w-4 h-4" /></Button>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <p className="text-muted-foreground text-center py-8">您的知識庫中還沒有文件。</p>
        )}
      </div>
    </div>
  )
}

// --- 設定面板 ---
const SettingsPanel = ({ user, token, showSuccessAlert, showErrorAlert, handleDeleteAllDocuments }: any) => {
  const { setTheme } = useTheme()
  const [fullName, setFullName] = useState(user?.full_name || '')
  const [oldPassword, setOldPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [isUpdatingProfile, setIsUpdatingProfile] = useState(false)
  const [isUpdatingPassword, setIsUpdatingPassword] = useState(false)

  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsUpdatingProfile(true)
    try {
      const response = await fetch(`${API_BASE_URL}/user/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ full_name: fullName }),
      })

      if (response.ok) {
        showSuccessAlert("個人資訊已更新！")
        // Optionally, refresh user info in auth context if needed
      } else {
        const errorData = await response.json()
        showErrorAlert(`更新失敗: ${errorData.detail || response.statusText}`)
      }
    } catch (error) {
      console.error("更新個人資訊失敗", error)
      showErrorAlert("更新失敗，請檢查網絡或後端服務")
    } finally {
      setIsUpdatingProfile(false)
    }
  }

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault()
    if (newPassword.length < 6) {
      showErrorAlert("新密碼長度不能少於 6 個字符")
      return
    }
    setIsUpdatingPassword(true)
    try {
      const response = await fetch(`${API_BASE_URL}/user/password`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ old_password: oldPassword, new_password: newPassword }),
      })

      if (response.ok) {
        showSuccessAlert("密碼已成功修改！")
        setOldPassword('')
        setNewPassword('')
      } else {
        const errorData = await response.json()
        showErrorAlert(`密碼修改失敗: ${errorData.detail || response.statusText}`)
      }
    } catch (error) {
      console.error("修改密碼失敗", error)
      showErrorAlert("修改密碼失敗，請檢查網絡或後端服務")
    } finally {
      setIsUpdatingPassword(false)
    }
  }

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-serif font-bold">系統設定</h2>
        <p className="text-muted-foreground">管理您的帳號、外觀和知識庫設定。</p>
      </div>

      {/* 外觀設定 */}
      <Card>
        <CardHeader>
          <CardTitle>外觀</CardTitle>
          <CardDescription>選擇您喜歡的介面主題。</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" onClick={() => setTheme('light')}><Sun className="mr-2 h-4 w-4"/>淺色</Button>
            <Button variant="outline" onClick={() => setTheme('dark')}><Moon className="mr-2 h-4 w-4"/>深色</Button>
            <Button variant="outline" onClick={() => setTheme('system')}><Laptop className="mr-2 h-4 w-4"/>系統</Button>
          </div>
        </CardContent>
      </Card>

      {/* 帳號設定 */}
      <Card>
        <CardHeader>
          <CardTitle>帳號設定</CardTitle>
          <CardDescription>更新您的個人資訊和密碼。</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <form onSubmit={handleProfileUpdate} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="fullName">姓名</Label>
              <Input id="fullName" value={fullName} onChange={e => setFullName(e.target.value)} placeholder="您的姓名" />
            </div>
            <Button type="submit" disabled={isUpdatingProfile}>
              {isUpdatingProfile && <Loader2 className="mr-2 h-4 w-4 animate-spin" />} 更新資訊
            </Button>
          </form>
          <div className="border-t pt-6">
            <form onSubmit={handlePasswordChange} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="oldPassword">舊密碼</Label>
                <Input id="oldPassword" type="password" value={oldPassword} onChange={e => setOldPassword(e.target.value)} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="newPassword">新密碼</Label>
                <Input id="newPassword" type="password" value={newPassword} onChange={e => setNewPassword(e.target.value)} required />
              </div>
              <Button type="submit" variant="secondary" disabled={isUpdatingPassword || !oldPassword || !newPassword}>
                {isUpdatingPassword && <Loader2 className="mr-2 h-4 w-4 animate-spin" />} 修改密碼
              </Button>
            </form>
          </div>
        </CardContent>
      </Card>

      {/* 危險區域 */}
      <Card className="border-destructive">
        <CardHeader>
          <CardTitle className="text-destructive">危險區域</CardTitle>
          <CardDescription>這些操作是不可逆的，請謹慎使用。</CardDescription>
        </CardHeader>
        <CardContent>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive">刪除所有文檔</Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>您確定嗎？</AlertDialogTitle>
                <AlertDialogDescription>
                  此操作將永久刪除您知識庫中的 **所有** 文檔，且無法恢復。請確認您真的要這麼做。
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>取消</AlertDialogCancel>
                <AlertDialogAction onClick={handleDeleteAllDocuments}>是的，刪除所有文檔</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </CardContent>
      </Card>
    </div>
  )
}


// --- 抽離 State 和邏輯的 Hook ---
const useDashboardState = () => {
  const { user, token, isLoading: authLoading } = useAuth()
  const [activeTab, setActiveTab] = useState("query")
  const [query, setQuery] = useState("")
  const [conversation, setConversation] = useState<ConversationMessage[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [uploadedFiles, setUploadedFiles] = useState<Document[]>([])
  const [uploadingFiles, setUploadingFiles] = useState<UploadingFile[]>([])
  const [alert, setAlert] = useState<{type: 'success' | 'error', message: string} | null>(null)
  const conversationEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!authLoading && token) {
      fetchUserDocuments()
    }
  }, [token, authLoading])

  useEffect(() => {
    conversationEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [conversation, isLoading])

  useEffect(() => {
    if (alert) {
      const timer = setTimeout(() => setAlert(null), 3000)
      return () => clearTimeout(timer)
    }
  }, [alert])

  const showSuccessAlert = (message: string) => setAlert({ type: 'success', message })
  const showErrorAlert = (message: string) => setAlert({ type: 'error', message })

  const fetchUserDocuments = async () => {
    if (!token) return
    try {
      const response = await fetch(`${API_BASE_URL}/documents`, { headers: { 'Authorization': `Bearer ${token}` } })
      if (response.ok) {
        const data = await response.json()
        setUploadedFiles(data || [])
      }
    } catch (error) {
      console.error("獲取文檔列表失敗", error)
      showErrorAlert("無法載入文檔列表")
    }
  }

  const uploadFile = async (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    setUploadingFiles(prev => prev.map(f => f.file === file ? { ...f, progress: 10 } : f));
    try {
      const response = await fetch(`${API_BASE_URL}/upload`, { method: 'POST', headers: { 'Authorization': `Bearer ${token}` }, body: formData });
      if (response.ok) {
        setUploadingFiles(prev => prev.map(f => f.file === file ? { ...f, status: 'success', progress: 100 } : f));
      } else {
        const errorText = await response.text();
        setUploadingFiles(prev => prev.map(f => f.file === file ? { ...f, status: 'error', error: `上傳失敗 (${response.status})` } : f));
        throw new Error(`上傳失敗: ${response.status}`);
      }
    } catch (error) {
      setUploadingFiles(prev => prev.map(f => f.file === file ? { ...f, status: 'error', error: error instanceof Error ? error.message : '上傳失敗' } : f));
      throw error;
    }
  };

  const handleFiles = async (files: FileList | null | File[]) => {
    if (!token || !files) return;
    const fileArray = Array.from(files);
    const newUploadingFiles = fileArray.map(file => ({ file, progress: 0, status: 'uploading' as const }));
    setUploadingFiles(prev => [...prev, ...newUploadingFiles]);
    await Promise.allSettled(fileArray.map(uploadFile));
    await fetchUserDocuments();
    setTimeout(() => setUploadingFiles(prev => prev.filter(f => f.status !== 'success')), 2000);
  };

  const removeUploadingFile = (file: File) => setUploadingFiles(prev => prev.filter(f => f.file !== file));

  const retryUpload = async (file: File) => {
    setUploadingFiles(prev => prev.map(f => f.file === file ? { ...f, status: 'uploading', progress: 0, error: undefined } : f));
    try {
      await uploadFile(file);
      await fetchUserDocuments();
    } catch (error) {
      console.error(`重試失敗: ${file.name}`, error);
    }
  };

  const handleDeleteDocument = async (documentId: number) => {
    if (!token) return;
    try {
      const response = await fetch(`${API_BASE_URL}/documents/${documentId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${token}` } });
      if (response.ok) {
        fetchUserDocuments();
        showSuccessAlert("文檔已刪除")
      } else {
        showErrorAlert('刪除失敗');
      }
    } catch (error) {
      showErrorAlert('刪除失敗');
    }
  };

  const handleDeleteAllDocuments = async () => {
    if (!token) return;
    try {
      const response = await fetch(`${API_BASE_URL}/documents/all`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      })

      if (response.ok) {
        showSuccessAlert("所有文檔均已刪除。")
        fetchUserDocuments() // 重新獲取文檔列表
      } else {
        const errorData = await response.json()
        showErrorAlert(`刪除失敗: ${errorData.detail || response.statusText}`)
      }
    } catch (error) {
      console.error("刪除所有文檔失敗", error)
      showErrorAlert("操作失敗，請檢查網絡或後端服務")
    }
  }

  const handleQuery = async () => {
    if (!query.trim() || !token) return;
    const currentQuery = query.trim();
    setIsLoading(true);
    const userMessage: ConversationMessage = { id: `user-${Date.now()}`, type: 'user', content: currentQuery, timestamp: new Date().toISOString() };
    setConversation(prev => [...prev, userMessage]);
    setQuery('');

    try {
      const conversationContext = conversation.slice(-8).map(msg => ({ role: msg.type === 'user' ? 'user' : 'assistant', content: msg.content }));
      const response = await fetch(`${API_BASE_URL}/query`, { method: 'POST', headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ query: currentQuery, conversation_history: conversationContext }) });
      if (response.ok) {
        const data = await response.json();
        const assistantMessage: ConversationMessage = { id: `assistant-${Date.now()}`, type: 'assistant', content: data.answer || '未找到答案', query: currentQuery, sources: data.sources || [], timestamp: new Date().toISOString() };
        setConversation(prev => [...prev, assistantMessage]);
      } else {
        const errorText = await response.text();
        const errorMessage: ConversationMessage = { id: `assistant-${Date.now()}`, type: 'assistant', content: `查詢出錯: ${errorText}`, query: currentQuery, timestamp: new Date().toISOString() };
        setConversation(prev => [...prev, errorMessage]);
      }
    } catch (error) {
      const errorMessage: ConversationMessage = { id: `assistant-${Date.now()}`, type: 'assistant', content: '網路請求失敗，請檢查後端服務是否正常運作。', query: currentQuery, timestamp: new Date().toISOString() };
      setConversation(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearConversation = () => setConversation([]);
  const exportConversation = () => { /* 匯出邏輯保持不變 */ };
  const formatFileSize = (bytes: number) => { if (bytes === 0) return '0 Bytes'; const k = 1024; const sizes = ['Bytes', 'KB', 'MB', 'GB']; const i = Math.floor(Math.log(bytes) / Math.log(k)); return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]; };
  const formatDate = (dateString: string) => new Date(dateString).toLocaleDateString('zh-TW');

  return { user, token, authLoading, activeTab, setActiveTab, query, setQuery, conversation, setConversation, isLoading, setIsLoading, uploadedFiles, setUploadedFiles, uploadingFiles, setUploadingFiles, alert, conversationEndRef, fetchUserDocuments, handleFiles, removeUploadingFile, retryUpload, handleDeleteDocument, handleDeleteAllDocuments, handleQuery, clearConversation, exportConversation, formatFileSize, formatDate, showSuccessAlert, showErrorAlert };
}