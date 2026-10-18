import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  //開発サーバーのみで適用される設定
  server: {
    proxy: {
      // /apiで始まるリクエストを/apiを除いてAPI Gatewayに渡す
      '/api': {
        target: 'https://dovfxkxzc1.execute-api.ap-northeast-1.amazonaws.com', // 転送先のAPI Gateway
        changeOrigin: true, //Hostヘッダーを転送先オリジン（API Gateway）に変更する
        rewrite: (path) => path.replace(/^\/api/, ""), //先頭の /apiを取り除く
      },
    },
  },
})
