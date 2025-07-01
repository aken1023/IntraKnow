"use client"

import React, { useState } from 'react'
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Loader2, UserPlus } from "lucide-react"
import { useAuth } from './auth-context'

interface RegisterFormProps {
  onSwitchToLogin: () => void
}

export const RegisterForm: React.FC<RegisterFormProps> = ({ onSwitchToLogin }) => {
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [passwordError, setPasswordError] = useState('')
  
  const { register, isLoading, error } = useAuth()

  const validatePassword = (password: string, confirmPassword: string) => {
    if (password.length > 0 && password.length < 6) {
      setPasswordError('密碼至少需要6個字符')
      return false
    }
    if (password && confirmPassword && password !== confirmPassword) {
      setPasswordError('兩次輸入的密碼不一致')
      return false
    }
    setPasswordError('')
    return true
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!validatePassword(password, confirmPassword)) {
      return
    }
    
    if (username && email && password) {
      await register(username, email, password, fullName || undefined)
    }
  }

  return (
    <Card className="w-full max-w-md mx-auto bg-transparent border-none shadow-none">
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          {(error || passwordError) && (
            <Alert variant="destructive">
              <AlertDescription>{error || passwordError}</AlertDescription>
            </Alert>
          )}
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="username-reg">用戶名 *</Label>
              <Input
                id="username-reg"
                type="text"
                placeholder="設定您的用戶名"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                disabled={isLoading}
                className="bg-background/80"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="fullName-reg">姓名</Label>
              <Input
                id="fullName-reg"
                type="text"
                placeholder="（選填）"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                disabled={isLoading}
                className="bg-background/80"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email-reg">郵箱 *</Label>
            <Input
              id="email-reg"
              type="email"
              placeholder="請輸入有效的郵箱地址"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={isLoading}
              className="bg-background/80"
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="password-reg">密碼 *</Label>
            <Input
              id="password-reg"
              type="password"
              placeholder="至少6個字符"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value)
                validatePassword(e.target.value, confirmPassword)
              }}
              required
              disabled={isLoading}
              className="bg-background/80"
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="confirmPassword-reg">確認密碼 *</Label>
            <Input
              id="confirmPassword-reg"
              type="password"
              placeholder="請再次輸入密碼"
              value={confirmPassword}
              onChange={(e) => {
                setConfirmPassword(e.target.value)
                validatePassword(password, e.target.value)
              }}
              required
              disabled={isLoading}
              className="bg-background/80"
            />
          </div>
          
          <Button 
            type="submit" 
            className="w-full font-semibold tracking-wider"
            disabled={isLoading || !username || !email || !password || !confirmPassword || !!passwordError}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                處理中...
              </>
            ) : (
              <>
                <UserPlus className="mr-2 h-4 w-4" />
                建立帳戶
              </>
            )}
          </Button>
        </form>
        
        <div className="mt-6 text-center text-sm text-muted-foreground">
          已經有帳號了？{' '}
          <button
            type="button"
            onClick={onSwitchToLogin}
            className="font-medium text-primary/90 hover:text-primary transition-colors duration-200 underline-offset-4 hover:underline"
            disabled={isLoading}
          >
            立即登入
          </button>
        </div>
      </CardContent>
    </Card>
  )
} 