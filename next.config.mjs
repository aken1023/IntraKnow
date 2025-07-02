import path from 'path'

/** @type {import('next').NextConfig} */
const nextConfig = {
  // 只在開發環境中使用 rewrites
  async rewrites() {
    // 在生產環境中，Nginx 會處理代理，所以不需要 rewrites
    if (process.env.NODE_ENV === 'production') {
      return []
    }
    
    return [
      {
        source: '/api/auth/:path*',
        destination: 'http://localhost:8000/auth/:path*',
      },
      {
        source: '/api/:path*',
        destination: 'http://localhost:8000/api/:path*',
      }
    ]
  },
  poweredByHeader: false,
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    domains: ['localhost', 'placeholder.com'],
    formats: ['image/avif', 'image/webp'],
  },
  reactStrictMode: true,
  swcMinify: true,
  output: 'standalone',
  webpack: (config, { isServer }) => {
    // 確保路徑別名在所有環境中正常工作
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': path.resolve(process.cwd()),
    }
    return config
  },
  // 生產環境優化
  compress: true,
  generateEtags: true,
  trailingSlash: false,
}

export default nextConfig
