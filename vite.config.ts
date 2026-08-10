/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const base = process.env.GITHUB_PAGES === 'true' ? '/svil-baduk/' : '/'

export default defineConfig({
  base,
  plugins: [react()],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  test: {
    // 순수 로직(node)과 컴포넌트(jsdom)를 분리 — 엔진 테스트는 계속 빠르게 유지
    projects: [
      {
        extends: true,
        test: {
          name: 'engine',
          environment: 'node',
          include: [
            'src/{engine,ai,sgf,game,learn,profile,solo,p2p,settings,styles,i18n,history}/**/*.test.ts',
          ],
        },
      },
      {
        extends: true,
        test: {
          name: 'ui',
          environment: 'jsdom',
          setupFiles: ['./src/test/setup.ts'],
          include: ['src/{components,screens,router,test}/**/*.test.{ts,tsx}'],
        },
      },
    ],
  },
})
