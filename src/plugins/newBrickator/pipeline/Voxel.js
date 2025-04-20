import Brick from "./Brick.js"

export default class Voxel {
  constructor (position) {
    this.isLego = this.isLego.bind(this)
    this.makeLego = this.makeLego.bind(this)
    this.make3dPrinted = this.make3dPrinted.bind(this)
    this.position = position
    this.brick = false
    this.enabled = true
    this.neighbors = {
      Zp: null,
      Zm: null,
      Xp: null,
      Xm: null,
      Yp: null,
      Ym: null,
    }
  }

  static initClass () {
    this.sizeFromVoxels = voxels => {
      let size = {}
      voxels.forEach(voxel => {
        // init values
        if (size.maxX == null) {
          size.maxX = size.minX != null ? size.minX : size.minX = voxel.position.x
        }
        if (size.maxY == null) {
          size.maxY = size.minY != null ? size.minY : size.minY = voxel.position.y
        }
        if (size.maxZ == null) {
          size.maxZ = size.minZ != null ? size.minZ : size.minZ = voxel.position.z
        }

        if (size.minX > voxel.position.x) {
          size.minX = voxel.position.x
        }
        if (size.minY > voxel.position.y) {
          size.minY = voxel.position.y
        }
        if (size.minZ > voxel.position.z) {
          size.minZ = voxel.position.z
        }

        if (size.maxX < voxel.position.x) {
          size.maxX = voxel.position.x
        }
        if (size.maxY < voxel.position.y) {
          size.maxY = voxel.position.y
        }
        if (size.maxZ < voxel.position.z) {
          return size.maxZ = voxel.position.z
        }
      })

      size = {
        x: (size.maxX - size.minX) + 1,
        y: (size.maxY - size.minY) + 1,
        z: (size.maxZ - size.minZ) + 1,
      }

      return size
    }

    this.fractionOfConnections = voxels => {
      let minZ = null
      let maxZ = null

      let voxelCounter = 0
      let connectionCounter = 0

      voxels.forEach((voxel) => {
        if (maxZ == null) {
          maxZ = minZ != null ? minZ : minZ = voxel.position.z
        }
        // TODO: Is this needed?
        // if (minZ > voxel.position.z) {
        //   const minY = voxel.position.z
        // }
        if (maxZ < voxel.position.z) {
          return maxZ = voxel.position.z
        }
      })
      voxels.forEach((voxel) => {
        if (voxel.position.z === maxZ) {
          voxelCounter++
          if (voxel.neighbors[Brick.direction.Zp] !== null) {
            return connectionCounter++
          }
        }
        else if (voxel.position.z === minZ) {
          voxelCounter++
          if (voxel.neighbors[Brick.direction.Zm] !== null) {
            return connectionCounter++
          }
        }
      })

      return connectionCounter / voxelCounter
    }
  }

  isLego () {
    return this.enabled
  }

  makeLego () {
    return this.enabled = true
  }

  make3dPrinted () {
    return this.enabled = false
  }
}
Voxel.initClass()
