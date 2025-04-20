export default {
  voxelize (model, lineStepSize, floatDelta, voxelRoundingThreshold,
    progressCallback) {
    this.floatDelta = floatDelta
    this.voxelRoundingThreshold = voxelRoundingThreshold
    const grid = []
    this._resetProgress()
    this._forEachPolygon(model, function (p0, p1, p2, direction, progress) {
      this._voxelizePolygon(
        p0,
        p1,
        p2,
        direction,
        lineStepSize,
        grid,
      )
      return this._postProgress(progress, progressCallback)
    })

    progressCallback({
      state: "finished",
      data: grid,
    })
  },

  _voxelizePolygon (p0, p1, p2, dZ, lineStepSize, grid) {
    // transform model coordinates to voxel coordinates
    // (object may be moved/rotated)

    // store information for filling solids
    let i; let longSide; let shortSide1; let shortSide2; let shortSideLength1; let shortSideLength2
    let step
    let step1
    const direction = dZ

    const l0len = this._getLength(p0, p1)
    const l1len = this._getLength(p1, p2)
    const l2len = this._getLength(p2, p0)

    // sort for short and long side
    if ((l0len >= l1len) && (l0len >= l2len)) {
      longSide = {start: p0, end: p1}
      shortSide1 = {start: p1, end: p2}
      shortSide2 = {start: p2, end: p0}

      shortSideLength1 = l1len
      shortSideLength2 = l2len
    }
    else if ((l1len >= l0len) && (l1len >= l2len)) {
      longSide = {start: p1, end: p2}
      shortSide1 = {start: p1, end: p0}
      shortSide2 = {start: p0, end: p2}

      shortSideLength1 = l0len
      shortSideLength2 = l2len
    }
    else { // if l2len >= l0len and l2len >= l1len
      longSide = {start: p2, end: p0}
      shortSide1 = {start: p2, end: p1}
      shortSide2 = {start: p1, end: p0}

      shortSideLength1 = l1len
      shortSideLength2 = l0len
    }

    const longSideStepSize = (1 / (shortSideLength1 + shortSideLength2)) * lineStepSize

    let longSideIndex = 0

    for (i = 0, step = lineStepSize / shortSideLength1; i <= 1; i += step) {
      p0 = this._interpolateLine(shortSide1, i)
      p1 = this._interpolateLine(longSide, longSideIndex)
      longSideIndex += longSideStepSize
      this._voxelizeLine(p0, p1, direction, lineStepSize, grid)
    }

    for (i = 0, step1 = lineStepSize / shortSideLength2; i <= 1; i += step1) {
      p0 = this._interpolateLine(shortSide2, i)
      p1 = this._interpolateLine(longSide, longSideIndex)
      longSideIndex += longSideStepSize
      this._voxelizeLine(p0, p1, direction, lineStepSize, grid)
    }

  },

  _getLength ({x: x1, y: y1, z: z1}, {x: x2, y: y2, z: z2}) {
    const dx = x2 - x1
    const dy = y2 - y1
    const dz = z2 - z1
    return Math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
  },

  _interpolateLine ({start: {x: x1, y: y1, z: z1},
    end: {x: x2, y: y2, z: z2}}, i) {
    i = Math.min(i, 1.0)
    const x = x1 + ((x2 - x1) * i)
    const y = y1 + ((y2 - y1) * i)
    const z = z1 + ((z2 - z1) * i)
    return {x, y, z}
  },

  /*
   * Voxelizes the line from a to b. Stores data in each generated voxel.
   *
   * @param {point} a the start point of the line
   * @param {point} b the end point of the line
   * @param {Number} direction direction value that is associated with the face
   * that this line is part of. Refer to HullVoxelizer to see how this
   * value is computed.
   * @param {Number} stepSize the stepSize to use for sampling the line
   * @param {Array} grid the voxel grid
   */
  _voxelizeLine (a, b, direction, stepSize, grid) {
    const length = this._getLength(a, b)
    const dx = ((b.x - a.x) / length) * stepSize
    const dy = ((b.y - a.y) / length) * stepSize
    const dz = ((b.z - a.z) / length) * stepSize

    let currentVoxel = {x: 0, y: 0, z: -1} // not a valid voxel because of z < 0
    const currentGridPosition = a

    for (let i = 0, end = length, step = stepSize, asc = step > 0; asc ? i <= end : i >= end; i += step) {
      var z
      if (!this._isOnVoxelBorder(currentGridPosition)) {
        const oldVoxel = currentVoxel
        currentVoxel = this._roundVoxelSpaceToVoxel(currentGridPosition)
        if ((oldVoxel.x !== currentVoxel.x) ||
        (oldVoxel.y !== currentVoxel.y) ||
        (oldVoxel.z !== currentVoxel.z)) {
          z = this._getGreatestZInVoxel(a, b, currentVoxel)
          this._setVoxel(currentVoxel, z, direction, grid)
        }
      }
      currentGridPosition.x += dx
      currentGridPosition.y += dy
      currentGridPosition.z += dz
    }
  },

  _isOnVoxelBorder ({x, y, z}) {
    for (const c of [x, y]) {
      if (Math.abs(0.5 - (c % 1)) < this.voxelRoundingThreshold) {
        return true
      }
    }
    return false
  },

  _roundVoxelSpaceToVoxel ({x, y, z}) {
    return {
      x: Math.round(x),
      y: Math.round(y),
      z: Math.round(z),
    }
  },

  _getGreatestZInVoxel (a, b, {x, y, z}) {
    let k
    const roundA = this._roundVoxelSpaceToVoxel(a)
    const roundB = this._roundVoxelSpaceToVoxel(b)

    const aIsInVoxel = (roundA.x === x) && (roundA.y === y) && (roundA.z === z)
    const bIsInVoxel = (roundB.x === x) && (roundB.y === y) && (roundB.z === z)

    if (aIsInVoxel && bIsInVoxel) {
      return Math.max(a.z, b.z)
    }
    if (aIsInVoxel && (a.z > b.z)) {
      return a.z
    }
    if (bIsInVoxel && (b.z > a.z)) {
      return b.z
    }

    const d = {x: b.x - a.x, y: b.y - a.y, z: b.z - a.z}

    if (d.z === 0) {
      // return the value that must be the greatest z in voxel --> a.z == b.z
      return a.z
    }

    if (d.x !== 0) {
      k = (x - 0.5 - a.x) / d.x
      if (k >= 0 && k <= 1) {
        return a.z + (k * d.z)
      }

      k = ((x + 0.5) - a.x) / d.x
      if (k >= 0 && k <= 1) {
        return a.z + (k * d.z)
      }
    }

    if (d.y !== 0) {
      k = (y - 0.5 - a.y) / d.y
      if (k >= 0 && k <= 1) {
        return a.z + (k * d.z)
      }

      k = ((y + 0.5) - a.y) / d.y
      if (k >= 0 && k <= 1) {
        return a.z + (k * d.z)
      }
    }

    if (d.z !== 0) {
      const minZ = z - 0.5
      k = (minZ - a.z) / d.z
      if (k >= 0 && k <= 1) {
        return minZ
      }

      const maxZ = z + 0.5
      k = (maxZ - a.z) / d.z
      if (k >= 0 && k <= 1) {
        return maxZ
      }
    }
  },

  _setVoxel ({x, y, z}, zValue, direction, grid) {
    if (!grid[x]) {
      grid[x] = []
    }
    if (!grid[x][y]) {
      grid[x][y] = []
    }
    const oldValue = grid[x][y][z]
    if (oldValue) {
      // Update dir if new zValue is higher than the old one
      // by at least floatDelta to avoid setting direction to -1 if it is
      // within the tolerance of floatDelta
      if (((direction !== 0) && (zValue > (oldValue.z + this.floatDelta))) ||
      // Prefer setting direction to 1 (i.e. close the voxel)
      ((direction === 1) && (zValue > (oldValue.z - this.floatDelta)))) {
        oldValue.z = zValue
        return oldValue.dir = direction
      }
    }
    else {
      return grid[x][y][z] = {z: zValue, dir: direction}
    }
  },

  _resetProgress () {
    return this.lastProgress = -1
  },

  _postProgress (progressFloat, callback) {
    const currentProgress = Math.round(100 * progressFloat)
    // only send progress updates in 1% steps
    if (!(currentProgress > this.lastProgress)) {
      return
    }
    this.lastProgress = currentProgress
    return callback({state: "progress", progress: currentProgress})
  },

  _forEachPolygon (model, visitor) {
    const {
      faceVertexIndices,
    } = model
    const {
      coordinates,
    } = model
    const {
      directions,
    } = model
    const {
      length,
    } = directions
    for (let i = 0, end = length, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) {
      const i3 = i * 3
      const p0 = {
        x: coordinates[faceVertexIndices[i3] * 3],
        y: coordinates[(faceVertexIndices[i3] * 3) + 1],
        z: coordinates[(faceVertexIndices[i3] * 3) + 2],
      }
      const p1 = {
        x: coordinates[faceVertexIndices[i3 + 1] * 3],
        y: coordinates[(faceVertexIndices[i3 + 1] * 3) + 1],
        z: coordinates[(faceVertexIndices[i3 + 1] * 3) + 2],
      }
      const p2 = {
        x: coordinates[faceVertexIndices[i3 + 2] * 3],
        y: coordinates[(faceVertexIndices[i3 + 2] * 3) + 1],
        z: coordinates[(faceVertexIndices[i3 + 2] * 3) + 2],
      }
      const direction = directions[i]

      visitor(p0, p1, p2, direction, i / length)
    }
  },
}
