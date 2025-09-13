import VolumeFillWorker from './VolumeFillWorker.js'

self.onmessage = (event) => {
  const { type, data } = event.data || {}
  if (type === 'fillGrid') {
    const { gridPOJO } = data
    const callback = (message) => {
      self.postMessage(message)
    }
    try {
      VolumeFillWorker.fillGrid(gridPOJO, callback)
    } catch (err) {
      self.postMessage({ state: 'error', error: (err && err.message) ? err.message : String(err) })
    }
  }
}

