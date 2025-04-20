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
        return this.resolve({grid})
      }
    }

    this.worker = this._getWorker()
    this.worker.fillGrid(
      gridPOJO,
      callback,
    )

    return new Promise((resolve, reject) => {
      this.resolve = resolve
    })
  }

  terminate () {
    if (this.worker != null) {
      this.worker.terminate()
    }
    return this.worker = null
  }

  _getWorker () {
    if (this.worker != null) {
      return this.worker
    }
    return operative(VolumeFillWorker)
  }
}
