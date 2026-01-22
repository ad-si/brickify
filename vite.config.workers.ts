import path from 'path'
import { fileURLToPath } from 'url'

import { defineConfig } from 'vite'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// Separate config for building standalone worker files
export default defineConfig({
  publicDir: false,
  build: {
    lib: {
      entry: {
        'hullVoxel.worker': path.resolve(__dirname, 'src/plugins/newBrickator/pipeline/voxelization/hullVoxel.worker.ts'),
        'volumeFill.worker': path.resolve(__dirname, 'src/plugins/newBrickator/pipeline/voxelization/volumeFill.worker.ts'),
      },
      formats: ['es'],
      fileName: (_, entryName) => `${entryName}.js`,
    },
    outDir: 'public/js/workers',
    emptyOutDir: true,
    minify: false,
    rollupOptions: {
      output: {
        // Ensure everything is bundled into single files
        inlineDynamicImports: false,
      },
    },
  },
})
