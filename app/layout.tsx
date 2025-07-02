import type { Metadata, Viewport } from 'next'
import { Noto_Sans_TC, Noto_Serif_TC } from 'next/font/google'
import './globals.css'
import { cn } from '@/lib/utils'
import { ViewportProvider } from '@/components/ui/viewport-provider'
import { ThemeProvider } from '@/components/theme-provider'
import { AuthProvider } from '@/components/auth/auth-context'

const fontSans = Noto_Sans_TC({
  subsets: ['latin'],
  variable: '--font-sans',
  weight: ['400', '500', '700'],
})

const fontSerif = Noto_Serif_TC({
  subsets: ['latin'],
  variable: '--font-serif',
  weight: ['400', '600', '700'],
})

export const metadata: Metadata = {
  title: '企業知識庫系統',
  description: '使用 LlamaIndex 和 FAISS 構建的企業級知識檢索系統',
  generator: 'Next.js',
  metadataBase: new URL(process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3001'),
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="zh-Hant" suppressHydrationWarning>
      <head>
        <meta name="theme-color" content="#ffffff" />
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.json" />
      </head>
      <body className={cn(
        "min-h-screen bg-background font-sans antialiased",
        fontSans.variable,
        fontSerif.variable
      )}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          <AuthProvider>
            <ViewportProvider>
              <main className="relative flex min-h-screen flex-col">
                {children}
              </main>
            </ViewportProvider>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}
