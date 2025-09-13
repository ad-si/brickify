import HullVoxelWorker from './HullVoxelWorker.js'

self.onmessage = (event) => {
  const { type, data } = event.data || {}
  if (type === 'voxelize') {
    const { model, lineStepSize, floatDelta, voxelRoundingThreshold } = data
    const progressCallback = (message) => {
      // Forward progress/finished messages to main thread
      self.postMessage(message)
    }
    try {
      HullVoxelWorker.voxelize(
        model,
        lineStepSize,
        floatDelta,
        voxelRoundingThreshold,
        progressCallback,
      )
    } catch (err) {
      self.postMessage({ state: 'error', error: (err && err.message) ? err.message : String(err) })
    }
  }
}

