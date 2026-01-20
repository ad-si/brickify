// Standalone worker for volume fill

const VolumeFillWorker = {
  fillGrid (grid, callback) {
    let voxelColumn; let voxelPlane; let x; let y
    const numVoxelsX = grid.length - 1
    let numVoxelsY = 0
    let numVoxelsZ = 0
    for (x in grid) {
      voxelPlane = grid[x]
      numVoxelsY = Math.max(numVoxelsY, voxelPlane.length - 1)
      for (y in voxelPlane) {
        voxelColumn = voxelPlane[y]
        numVoxelsZ = Math.max(numVoxelsZ, voxelColumn.length - 1)
      }
    }

    this._resetProgress()

    for (x in grid) {
      voxelPlane = grid[x]
      x = parseInt(x)
      for (y in voxelPlane) {
        voxelColumn = voxelPlane[y]
        y = parseInt(y)
        this._postProgress(callback, x, y, numVoxelsX, numVoxelsY)
        this._fillUp(grid, x, y, numVoxelsZ)
      }
    }
    return callback({state: 'finished', data: grid})
  },

  _fillUp (grid, x, y, numVoxelsZ) {
    let insideModel = false
    let z = 0
    const currentFillVoxelQueue = []

    while (z <= numVoxelsZ) {
      if (grid[x][y][z] != null) {
        const { dir } = grid[x][y][z]
        this._setVoxels(grid, x, y, currentFillVoxelQueue, 0)
        if (dir === 1) insideModel = false
        else if (dir === -1) insideModel = true
      }
      else {
        if (insideModel) currentFillVoxelQueue.push(z)
      }
      z++
    }
  },

  _setVoxels (grid, x, y, zValues, voxelData) {
    let zValue
    while (zValue = zValues.pop()) {
      this._setVoxel(grid, x, y, zValue, voxelData)
    }
  },

  _setVoxel (grid, x, y, z, voxelData) {
    if (grid[x] == null) grid[x] = []
    if (grid[x][y] == null) grid[x][y] = []
    if (grid[x][y][z] == null) grid[x][y][z] = []
    grid[x][y][z] = voxelData
  },

  _resetProgress () { this.lastProgress = -1 },
  _postProgress (callback, x, y, numVoxelsX, numVoxelsY) {
    const progress = Math.round((100 * ((((x - 1) * numVoxelsY) + y) - 1)) / numVoxelsX / numVoxelsY)
    if (!(progress > this.lastProgress)) return
    this.lastProgress = progress
    callback({state: 'progress', progress})
  },
}

self.onmessage = (event) => {
  const { type, data } = event.data || {}
  if (type === 'fillGrid') {
    const { gridPOJO } = data
    const callback = (message) => self.postMessage(message)
    try {
      VolumeFillWorker.fillGrid(gridPOJO, callback)
    } catch (err) {
      self.postMessage({ state: 'error', error: (err && err.message) ? err.message : String(err) })
    }
  }
}

