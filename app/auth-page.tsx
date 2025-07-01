"use client"

import React, { useState } from 'react'
import { LoginForm } from '@/components/auth/login-form'
import { RegisterForm } from '@/components/auth/register-form'

export const AuthPage: React.FC = () => {
  const [isLogin, setIsLogin] = useState(true)

  return (
    <main className="responsive-container flex min-h-screen flex-col items-center justify-center py-12">
      <div className="w-full max-w-md text-center">
        <h1 className="text-4xl font-serif font-bold text-foreground mb-4 text-balance">
          {isLogin ? '歡迎回來' : '建立您的帳戶'}
        </h1>
        <p className="text-muted-foreground mb-8">
          {isLogin ? '登入以繼續您的知識探索之旅。' : '只需幾步，即可開始打造您的個人知識庫。'}
        </p>
      </div>
      <div className="w-full max-w-sm">
        {isLogin ? (
          <LoginForm onSwitchToRegister={() => setIsLogin(false)} />
        ) : (
          <RegisterForm onSwitchToLogin={() => setIsLogin(true)} />
        )}
      </div>
    </main>
  )
} 