"use client"

import React, { useState } from 'react'
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Loader2, LogIn } from "lucide-react"
import { useAuth } from './auth-context'

interface LoginFormProps {
  onSwitchToRegister: () => void
}

export const LoginForm: React.FC<LoginFormProps> = ({ onSwitchToRegister }) => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const { login, isLoading, error } = useAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (username && password) {
      await login(username, password)
    }
  }

  return (
    <Card className="w-full max-w-md mx-auto bg-transparent border-none shadow-none">
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}
          
          <div className="space-y-2">
            <Label htmlFor="username">用戶名</Label>
            <Input
              id="username"
              type="text"
              placeholder="請輸入您的用戶名"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              disabled={isLoading}
              className="bg-background/80"
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="password">密碼</Label>
            <Input
              id="password"
              type="password"
              placeholder="請輸入您的密碼"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading}
              className="bg-background/80"
            />
          </div>
          
          <Button 
            type="submit" 
            className="w-full font-semibold tracking-wider"
            disabled={isLoading || !username || !password}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                處理中...
              </>
            ) : (
              <>
                <LogIn className="mr-2 h-4 w-4" />
                登入
              </>
            )}
          </Button>
        </form>
        
        <div className="mt-6 text-center text-sm text-muted-foreground">
          還沒有帳號？{' '}
          <button
            type="button"
            onClick={onSwitchToRegister}
            className="font-medium text-primary/90 hover:text-primary transition-colors duration-200 underline-offset-4 hover:underline"
            disabled={isLoading}
          >
            立即註冊
          </button>
        </div>
      </CardContent>
    </Card>
  )
} 