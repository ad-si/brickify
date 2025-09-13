import fs from 'fs'
import path from 'path'

import { defineConfig } from 'vite'
import legacy from '@vitejs/plugin-legacy'
import { viteCommonjs } from '@originjs/vite-plugin-commonjs'
import ViteYaml from '@modyfi/vite-plugin-yaml'
import { nodePolyfills } from 'vite-plugin-node-polyfills'


export default defineConfig({
  base: '/js/',
  plugins: [
    nodePolyfills(),
    legacy({
      targets: ['defaults', 'not IE 11']
    }),
    viteCommonjs(),
    ViteYaml()
  ],
  
  build: {
    chunkSizeWarningLimit: 600,
    rollupOptions: {
      input: {
        app: path.resolve(__dirname, 'src/client/main.js'),
        landingpage: path.resolve(__dirname, 'src/client/landingpage.js'),
        shared: path.resolve(__dirname, 'src/client/shared.js')
      },
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]'
      }
    },
    outDir: 'public/js',
    emptyOutDir: false,
    assetsDir: ''
  },
  publicDir: false,

  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      'path': 'path-browserify',
      'stream': 'stream-browserify'
    }
  },

  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development'),
    global: 'globalThis'
  },

  server: {
    port: 3001,
    proxy: {
      // Proxy API requests to your Express server
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  }
})
