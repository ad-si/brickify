import VolumeFillWorker from "./VolumeFillWorker.js"

export default class VolumeFiller {
  constructor () {
    this.terminate = this.terminate.bind(this)
  }

  fillGrid (grid, gridPOJO, options, progressCallback) {
    // fills spaces in the grid. Goes up from z=0 to z=max and looks for
    // voxels facing downwards (start filling), stops when it sees voxels
    // facing upwards

    const callback = message => {
      if (message.state === "progress") {
        return progressCallback(message.progress)
      }
      else { // if state is 'finished'
        grid.fromPojo(message.data)
        return {grid}
      }
    }

    return this._getWorker().then(worker => {
      this.worker = worker
      // Fallback to synchronous execution when worker is unavailable
      if (!worker || typeof worker.postMessage !== 'function') {
        return new Promise((resolve) => {
          const cb = (message) => {
            if (message.state === 'progress') {
              progressCallback(message.progress)
            } else if (message.state === 'finished') {
              grid.fromPojo(message.data)
              resolve({ grid })
            }
          }
          VolumeFillWorker.fillGrid(gridPOJO, cb)
        })
      }

      return new Promise((resolve, reject) => {
        const cleanup = () => {
          worker.removeEventListener('message', handleMessage)
          worker.removeEventListener('error', handleError)
        }
        const handleMessage = (event) => {
          const message = event.data
          if (!message || !message.state) return
          if (message.state === 'progress') {
            progressCallback(message.progress)
          } else if (message.state === 'finished') {
            cleanup()
            grid.fromPojo(message.data)
            resolve({ grid })
          } else if (message.state === 'error') {
            cleanup()
            reject(new Error(message.error || "Worker error"))
          }
        }
        const handleError = (err) => {
          cleanup()
          reject(err)
        }
        worker.addEventListener('message', handleMessage)
        worker.addEventListener('error', handleError, { once: true })
        worker.postMessage({ type: 'fillGrid', data: { gridPOJO } })
      })
    })
  }

  terminate () {
    if (this.worker != null && typeof this.worker.terminate === 'function') {
      this.worker.terminate()
    }
    return this.worker = null
  }

  _getWorker () {
    if (this.worker != null) {
      return Promise.resolve(this.worker)
    }
    if (typeof window === 'undefined') {
      return Promise.reject(new Error('Web Worker not available in this context'))
    }
    try {
      // Use relative path for static builds, absolute for server builds
      const workerPath = (typeof IS_STATIC_BUILD !== "undefined" && IS_STATIC_BUILD)
        ? "./js/workers/volumeFill.worker.js"
        : "/js/workers/volumeFill.worker.js"
      const worker = new Worker(workerPath)
      this.worker = worker
      return Promise.resolve(worker)
    } catch (e) {
      // Fallback: provide a dummy
      this.worker = {
        postMessage: () => {},
        addEventListener: () => {},
        removeEventListener: () => {},
        terminate: () => {},
      }
      return Promise.resolve(this.worker)
    }
  }
}
