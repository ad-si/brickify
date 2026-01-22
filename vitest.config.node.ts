import path from 'path'
import { fileURLToPath } from 'url'

import { defineConfig } from 'vitest/config'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },

  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'test'),
  },

  test: {
    include: ['test/**/*Tests.ts', 'test/**/general.ts', 'test/**/split.ts', 'test/**/merge.ts'],
    exclude: ['test/**/*.d.ts', 'test/mocks/**', 'test/**/sceneChaiHelper.ts', 'test/**/dummySyncObject.ts', 'test/core.ts'],
    environment: 'node',
    globals: true,
  },
})
