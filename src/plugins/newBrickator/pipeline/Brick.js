import log from "loglevel"

/*
 * @class Brick
 */
export default class Brick {
  static initClass () {
    this.direction = {
      Xp: "Xp",
      Xm: "Xm",
      Yp: "Yp",
      Ym: "Ym",
      Zp: "Zp",
      Zm: "Zm",
    }

    this.validBrickSizes = [
      [1, 1, 1], [1, 2, 1], [1, 3, 1], [1, 4, 1], [1, 6, 1], [1, 8, 1],
      [2, 2, 1], [2, 3, 1], [2, 4, 1], [2, 6, 1], [2, 8, 1], [2, 10, 1],
      [1, 1, 3], [1, 2, 3], [1, 3, 3], [1, 4, 3],
      [1, 6, 3], [1, 8, 3], [1, 10, 3], [1, 12, 3], [1, 16, 3],
      [2, 2, 3], [2, 3, 3], [2, 4, 3], [2, 6, 3], [2, 8, 3], [2, 10, 3],
    ]

    // Returns the array index of the first size that
    // matches isSizeEqual
    this.getSizeIndex = testSize => {
      for (let i = 0; i < this.validBrickSizes.length; i++) {
        const size = this.validBrickSizes[i]
        if (this.isSizeEqual(
          {x: testSize.x, y: testSize.y, z: testSize.z},
          {x: size[0], y: size[1], z: size[2]},
        )) {
          return i
        }
      }
      return -1
    }
  }

  // Returns true if the given size is a valid size
  static isValidSize (x, y, z) {
    for (const testSize of Array.from(Brick.validBrickSizes)) {
      if ((testSize[0] === x) && (testSize[1] === y) && (testSize[2] === z)) {
        return true
      }
      else if ((testSize[0] === y) && (testSize[1] === x) && (testSize[2] === z)) {
        return true
      }
    }
    return false
  }

  // Returns true if the two sizes are equal in terms of
  // same height and same x/y dimensions which may be
  // switched
  static isSizeEqual (a, b) {
    return (((a.x === b.x) && (a.y === b.y)) ||
    ((a.x === b.y) && (a.y === b.x))) && (a.z === b.z)
  }

  // Creates a brick out of the given set of voxels
  // Takes ownership of voxels without further processing
  constructor (arrayOfVoxels) {
    this.forEachVoxel = this.forEachVoxel.bind(this)
    this.getVoxel = this.getVoxel.bind(this)
    this.getPosition = this.getPosition.bind(this)
    this.getSize = this.getSize.bind(this)
    this.isSize = this.isSize.bind(this)
    this.getNeighbors = this.getNeighbors.bind(this)
    this.getNeighborsXY = this.getNeighborsXY.bind(this)
    this.getCover = this.getCover.bind(this)
    this.connectedBricks = this.connectedBricks.bind(this)
    this.splitUp = this.splitUp.bind(this)
    this.getVisualBrick = this.getVisualBrick.bind(this)
    this.setVisualBrick = this.setVisualBrick.bind(this)
    this.clear = this.clear.bind(this)
    this._clearData = this._clearData.bind(this)
    this._clearCache = this._clearCache.bind(this)
    this.clearNeighborsCache = this.clearNeighborsCache.bind(this)
    this.mergeWith = this.mergeWith.bind(this)
    this.hasValidSize = this.hasValidSize.bind(this)
    this.isHoleFree = this.isHoleFree.bind(this)
    this.isValid = this.isValid.bind(this)
    this.getStability = this.getStability.bind(this)
    this.fractionOfConnectionsInZDirection = this.fractionOfConnectionsInZDirection.bind(this)
    this.voxels = new Set()
    for (const voxel of Array.from(arrayOfVoxels)) {
      voxel.brick = this
      this.voxels.add(voxel)
    }
    this.label = null
  }

  // Enumerates over each voxel that belongs to this brick
  forEachVoxel (callback) {
    return this.voxels.forEach(callback)
  }

  // Returns the voxel the brick consists of, if it consists out
  // of one voxel. else returns null
  getVoxel () {
    if (this.voxels.size > 1) {
      return null
    }
    const iterator = this.voxels.entries()
    return iterator.next().value[0]
  }

  // Returns true if a voxel with this coordinates
  // belongs to this brick
  isVoxelInBrick (x, y, z) {
    let inBrick = false
    this.forEachVoxel((vox) => {
      if ((vox.position.x === x) &&
      (vox.position.y === y) &&
      (vox.position.z === z)) {
        return inBrick = true
      }
    })
    return inBrick
  }

  // Returns the {x, y, z} values of the voxel with
  // the smallest x, y and z.
  // To work properly, this function assumes that there
  // are no holes in the brick and the brick is a proper cuboid
  getPosition () {
    if (this._position != null) {
      return this._position
    }

    // To bring variables to correct scope
    let x = undefined
    let y = undefined
    let z = undefined

    this.forEachVoxel((voxel) => {
      if (x == null) {
        ({
          x,
        } = voxel.position)
      }
      x = Math.min(voxel.position.x, x)
      if (y == null) {
        ({
          y,
        } = voxel.position)
      }
      y = Math.min(voxel.position.y, y)
      if (z == null) {
        ({
          z,
        } = voxel.position)
      }
      return z = Math.min(voxel.position.z, z)
    })

    this._position = {
      x,
      y,
      z,
    }
    return this._position
  }

  // Returns the size of the brick
  getSize () {
    if (this._size != null) {
      return this._size
    }
    this._size = {}

    this.forEachVoxel(voxel => {
      // init values
      if (this._size.maxX == null) {
        this._size.maxX = this._size.minX != null ? this._size.minX : this._size.minX = voxel.position.x
      }
      if (this._size.maxY == null) {
        this._size.maxY = this._size.minY != null ? this._size.minY : this._size.minY = voxel.position.y
      }
      if (this._size.maxZ == null) {
        this._size.maxZ = this._size.minZ != null ? this._size.minZ : this._size.minZ = voxel.position.z
      }

      if (this._size.minX > voxel.position.x) {
        this._size.minX = voxel.position.x
      }
      if (this._size.minY > voxel.position.y) {
        this._size.minY = voxel.position.y
      }
      if (this._size.minZ > voxel.position.z) {
        this._size.minZ = voxel.position.z
      }

      if (this._size.maxX < voxel.position.x) {
        this._size.maxX = voxel.position.x
      }
      if (this._size.maxY < voxel.position.y) {
        this._size.maxY = voxel.position.y
      }
      if (this._size.maxZ < voxel.position.z) {
        return this._size.maxZ = voxel.position.z
      }
    })

    this._size = {
      x: (this._size.maxX - this._size.minX) + 1,
      y: (this._size.maxY - this._size.minY) + 1,
      z: (this._size.maxZ - this._size.minZ) + 1,
    }

    return this._size
  }

  isSize (x, y, z) {
    const size = this.getSize()
    if ((size.x === x) && (size.y === y) && (size.z === z)) {
      return true
    }
    else if ((size.x === y) && (size.y === x) && (size.z === z)) {
      return true
    }
    else {
      return false
    }
  }

  // Returns a set of all bricks that are next to this brick
  // in the given direction
  getNeighbors (direction) {
    /*
      TODO
      This check can now 2015-30-06 potentially be removed
      However, I am leaving this check in place for some time
      If the issue does not reappear within two weeks, I will remove it
    */
    // Checking the cache for correctness
    if ((this._neighbors != null ? this._neighbors[direction] : undefined) != null) {
      this._neighbors[direction].forEach(neighbor => {
        if (neighbor.voxels.size === 0) {
          log.warn("got outdated neighbor from cache")
          return this.clearNeighborsCache()
        }
      })
    }

    if ((this._neighbors != null ? this._neighbors[direction] : undefined) != null) {
      return this._neighbors[direction]
    }

    const neighbors = new Set()

    this.forEachVoxel(voxel => {
      if (voxel.neighbors[direction] != null) {
        const neighborBrick = voxel.neighbors[direction].brick
        if (neighborBrick && (neighborBrick !== this)) {
          return neighbors.add(neighborBrick)
        }
      }
    })

    if (this._neighbors == null) {
      this._neighbors = {}
    }
    this._neighbors[direction] = neighbors

    return this._neighbors[direction]
  }

  getNeighborsXY () {
    const neighbors = new Set();

    [Brick.direction.Xp, Brick.direction.Xm, Brick.direction.Yp,
      Brick.direction.Ym].forEach(direction => {
      return this.getNeighbors(direction)
        .forEach(brick => neighbors.add(brick))
    })

    return neighbors
  }

  /*
   * Returns whether this brick is completely covered by other bricks.
   * @return {Object}
   * @returnprop {Boolean} isCompletelyCovered is this brick completely covered
   * @returnprop {Set} coveringBricks the bricks that cover this brick
   */
  getCover () {
    if (this._isCoveredOnTop == null) {
      const stability = this.fractionOfConnectionsInZDirection(Brick.direction.Zp)
      this._isCoveredOnTop = stability > 0.99
    }

    return {
      isCompletelyCovered: this._isCoveredOnTop,
      coveringBricks: this.getNeighbors(Brick.direction.Zp),
    }
  }

  // Connected Bricks are neighbors in Zp and Zm direction
  // because they are connected with studs to each other
  connectedBricks () {
    const connectedBricks = new Set()

    this.getNeighbors(Brick.direction.Zp)
      .forEach(brick => connectedBricks.add(brick))

    this.getNeighbors(Brick.direction.Zm)
      .forEach(brick => connectedBricks.add(brick))

    return connectedBricks
  }

  // Splits up this brick in 1x1x1 bricks and returns them as a set
  // This brick has no voxels after this operation
  splitUp () {
    // Tell neighbors to update their cache
    for (const direction in Brick.direction) {
      const neighbors = this.getNeighbors(direction)
      neighbors.forEach(neighbor => neighbor.clearNeighborsCache())
    }

    // Create new bricks
    const newBricks = new Set()

    this.forEachVoxel((voxel) => {
      const brick = new Brick([voxel])
      return newBricks.add(brick)
    })

    this._clearData()
    return newBricks
  }

  // Returns the brick visualization that belongs to this brick
  getVisualBrick () {
    return this._visualBrick
  }

  // Sets the brick visualization that belongs to this brick
  setVisualBrick (visualBrick) {
    if (this._visualBrick !== visualBrick) {
      if (this._visualBrick != null) {
        this._visualBrick.setBrick(null)
      }
    }
    this._visualBrick = visualBrick
    return this._visualBrick != null ? this._visualBrick.setBrick(this) : undefined
  }

  // Removes all references to this brick from voxels
  // this brick has to be deleted after that
  clear () {
    // Clear references
    this.forEachVoxel(voxel => voxel.brick = false)
    // And stored data
    return this._clearData()
  }

  _clearData () {
    // clear stored data
    this._clearCache()
    this.setVisualBrick(null)
    return this.voxels.clear()
  }

  _clearCache () {
    this._size = null
    this._position = null
    this.label = null
    return this.clearNeighborsCache()
  }

  clearNeighborsCache () {
    this._neighbors = null
    return this._isCoveredOnTop = null
  }


  // Merges this brick with the other brick specified,
  // the other brick gets deleted in the process
  mergeWith (otherBrick) {
    // Tell neighbors to update their cache
    for (const direction in Brick.direction) {
      const neighbors = this.getNeighbors(direction)
      neighbors.forEach(neighbor => neighbor.clearNeighborsCache())

      const otherNeighbors = otherBrick.getNeighbors(direction)
      otherNeighbors.forEach(neighbor => neighbor.clearNeighborsCache())
    }

    // clear size, position and neighbors (to be recomputed)
    this._clearCache()

    // Clear reference to visual brick (needs to be recreated)
    this.setVisualBrick(null)

    // take voxels from other brick
    const newVoxels = new Set()

    otherBrick.forEachVoxel(voxel => newVoxels.add(voxel))

    otherBrick.clear()

    return newVoxels.forEach(voxel => {
      voxel.brick = this
      return this.voxels.add(voxel)
    })
  }

  // Returns true if the size of the brick matches one of @validBrickSizes
  hasValidSize () {
    const size = this.getSize()
    return Brick.isValidSize(size.x, size.y, size.z)
  }

  // Returns true if the brick has no holes in it, i.e. is a cuboid
  // voxels marked to be 3d printed count as holes
  isHoleFree () {
    let x; let y; let z
    let asc; let end
    const voxelCheck = {}

    const p = this.getPosition()
    const s = this.getSize()

    for ({
      x,
    } = p, end = p.x + s.x, asc = p.x <= end; asc ? x < end : x > end; asc ? x++ : x--) {
      var asc1; var end1
      for ({
        y,
      } = p, end1 = p.y + s.y, asc1 = p.y <= end1; asc1 ? y < end1 : y > end1; asc1 ? y++ : y--) {
        var asc2; var end2
        for ({
          z,
        } = p, end2 = p.z + s.z, asc2 = p.z <= end2; asc2 ? z < end2 : z > end2; asc2 ? z++ : z--) {
          voxelCheck[x + "-" + y + "-" + z] = false
        }
      }
    }

    this.forEachVoxel((voxel) => {
      const vp = voxel.position
      if (voxel.isLego()) {
        return voxelCheck[vp.x + "-" + vp.y + "-" + vp.z] = true
      }
    })

    let hasHoles = false
    for (const val in voxelCheck) {
      if (voxelCheck[val] === false) {
        hasHoles = true
        break
      }
    }

    return !hasHoles
  }

  // Returns true if the brick is valid
  // a brick is valid when it has voxels, is hole free and
  // has a valid size
  isValid () {
    return (this.voxels.size > 0) && this.hasValidSize() && this.isHoleFree()
  }

  getStability () {
    const s = this.getSize()
    const p = this.getPosition()
    const conBricks = this.connectedBricks()

    // Possible slots top & bottom
    const possibleSlots = s.x * s.y * 2

    // How many slots are actually connected?
    let usedSlots = 0

    const lowerZ = p.z - 1
    const upperZ = p.z + s.z

    // Test for each possible slot if neighbor bricks have
    // voxels that belong to this slot
    for (var {
        x,
      } = p, end = p.x + s.x, asc = p.x <= end; asc ? x < end : x > end; asc ? x++ : x--) {
      for (var {
          y,
        } = p, end1 = p.y + s.y, asc1 = p.y <= end1; asc1 ? y < end1 : y > end1; asc1 ? y++ : y--) {
        conBricks.forEach((brick) => {
          if (brick.isVoxelInBrick(x, y, upperZ)) {
            usedSlots++
          }
          if (brick.isVoxelInBrick(x, y, lowerZ)) {
            return usedSlots++
          }
        })
      }
    }

    return usedSlots / possibleSlots
  }

  fractionOfConnectionsInZDirection (directionZmOrZp) {
    let testZ
    const s = this.getSize()
    const p = this.getPosition()
    const conBricks = this.getNeighbors(directionZmOrZp)

    // Possible slots top or bottom
    const possibleSlots = s.x * s.y

    // How many slots are actually connected?
    let usedSlots = 0

    if (directionZmOrZp === Brick.direction.Zm) {
      testZ = p.z - 1
    }
    else if (directionZmOrZp === Brick.direction.Zp) {
      testZ = p.z + s.z
    }

    // Test for each possible slot if neighbor bricks have
    // voxels that belong to this slot
    for (var {
        x,
      } = p, end = p.x + s.x, asc = p.x <= end; asc ? x < end : x > end; asc ? x++ : x--) {
      for (var {
          y,
        } = p, end1 = p.y + s.y, asc1 = p.y <= end1; asc1 ? y < end1 : y > end1; asc1 ? y++ : y--) {
        conBricks.forEach((brick) => {
          if (brick.isVoxelInBrick(x, y, testZ)) {
            return usedSlots++
          }
        })
      }
    }

    return usedSlots / possibleSlots
  }
}
Brick.initClass()
