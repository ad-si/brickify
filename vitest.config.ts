import path from 'path';
import { fileURLToPath } from 'url';

import { defineConfig } from 'vitest/config';
import { nodePolyfills } from 'vite-plugin-node-polyfills';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';
import ViteYaml from '@modyfi/vite-plugin-yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default defineConfig({
  plugins: [
    nodePolyfills(),
    viteCommonjs(),
    ViteYaml(),
  ],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      path: 'path-browserify',
      stream: 'stream-browserify',
    },
  },

  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'test'),
    global: 'globalThis',
  },

  test: {
    include: ['testClient/**/*.test.ts', 'testClient/**/*Tests.ts'],
    exclude: ['testClient/setup.ts'],
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./testClient/setup.ts'],
  },
});
