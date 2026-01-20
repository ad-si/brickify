import path from 'path'
import { fileURLToPath } from 'url'

import { defineConfig } from 'vite'
import legacy from '@vitejs/plugin-legacy'
import { viteCommonjs } from '@originjs/vite-plugin-commonjs'
import ViteYaml from '@modyfi/vite-plugin-yaml'
import { nodePolyfills } from 'vite-plugin-node-polyfills'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// Plugin to replace server-dependent modules with static versions
function staticModulesPlugin() {
  const staticModelCache = path.resolve(__dirname, 'src/client/modelLoading/modelCacheStatic.js')
  const staticDataPackets = path.resolve(__dirname, 'src/client/sync/dataPacketsProxyStatic.js')

  return {
    name: 'static-modules',
    enforce: 'pre',
    resolveId(source, importer) {
      if (!importer) return null

      // Replace modelCache imports (handles both ./modelCache.js and ./modelLoading/modelCache.js)
      if (source.endsWith('modelCache.js') && !source.includes('Static')) {
        return staticModelCache
      }

      // Replace dataPacketsProxy imports
      if (source.endsWith('dataPacketsProxy.js') && !source.includes('Static')) {
        return staticDataPackets
      }

      return null
    }
  }
}

export default defineConfig({
  base: './',
  plugins: [
    staticModulesPlugin(),
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
        entryFileNames: 'js/[name].js',
        chunkFileNames: 'js/[name].js',
        assetFileNames: 'js/[name].[ext]'
      }
    },
    outDir: 'dist-static',
    emptyOutDir: true,
    assetsDir: 'assets',
    copyPublicDir: true
  },
  publicDir: 'public',

  resolve: {
    alias: [
      { find: '@', replacement: path.resolve(__dirname, 'src') },
      { find: 'path', replacement: 'path-browserify' },
      { find: 'stream', replacement: 'stream-browserify' },
      // Use localStorage-based proxy for static builds instead of server API
      {
        find: path.resolve(__dirname, 'src/client/sync/dataPacketsProxy.js'),
        replacement: path.resolve(__dirname, 'src/client/sync/dataPacketsProxyStatic.js')
      }
    ]
  },

  define: {
    'process.env.NODE_ENV': JSON.stringify('production'),
    global: 'globalThis',
    IS_STATIC_BUILD: true
  }
})
