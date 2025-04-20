import THREE from "three"

import BrickObject from "./BrickObject.js"

// This class provides basic functionality to create simple Voxel/Brick geometry
export default class GeometryCreator {
  constructor (globalConfig, grid) {
    this.getBrick = this.getBrick.bind(this)
    this.getBrickBox = this.getBrickBox.bind(this)
    this._getBrickGeometry = this._getBrickGeometry.bind(this)
    this._getStudsGeometry = this._getStudsGeometry.bind(this)
    this._getPlaneGeometry = this._getPlaneGeometry.bind(this)
    this.globalConfig = globalConfig
    this.grid = grid
    this.brickGeometryCache = {}
    this.studGeometryCache = {}
    this.highFiStudGeometryCache = {}
    this.planeGeometryCache = {}

    const studRotation = new THREE.Matrix4()
    studRotation.makeRotationX(1.571)

    const studTranslation = new THREE.Matrix4()
    studTranslation.makeTranslation(0, 0, this.globalConfig.studSize.height / 2)

    this.studGeometry = new THREE.CylinderGeometry(
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.height,
      7,
    )
    this.studGeometry.applyMatrix(studRotation)
    this.studGeometry.applyMatrix(studTranslation)

    this.highFiStudGeometry = new THREE.CylinderGeometry(
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.height,
      42,
    )

    this.highFiStudGeometry.applyMatrix(studRotation)
    this.highFiStudGeometry.applyMatrix(studTranslation)
  }

  getBrick (gridPosition, brickDimensions, materials, fidelity) {
    // returns a THREE.Geometry that uses the given material and is
    // transformed to match the given grid position
    const worldBrickSize = {
      x: brickDimensions.x * this.grid.spacing.x,
      y: brickDimensions.y * this.grid.spacing.y,
      z: brickDimensions.z * this.grid.spacing.z,
    }

    const geometries = {
      brickGeometry: this._getBrickGeometry(brickDimensions, worldBrickSize),
      studGeometry: this._getStudsGeometry(
        brickDimensions,
        worldBrickSize,
        this.studGeometryCache,
        this.studGeometry,
      ),
      highFiStudGeometry: this._getStudsGeometry(
        brickDimensions,
        worldBrickSize,
        this.highFiStudGeometryCache,
        this.highFiStudGeometry,
      ),
      planeGeometry: this._getPlaneGeometry(brickDimensions, worldBrickSize),
    }

    const brick = new BrickObject(
      geometries,
      materials,
      fidelity,
    )

    const worldBrickPosition = this.grid.mapVoxelToWorld(gridPosition)

    // translate so that the x:0 y:0 z:0 coordinate matches the models corner
    // (center of model is physical center of box)
    brick.translateX(worldBrickSize.x / 2.0)
    brick.translateY(worldBrickSize.y / 2.0)
    brick.translateZ(worldBrickSize.z / 2.0)

    // normal voxels have their origin in the middle, so translate the brick
    // to match the center of a voxel
    brick.translateX(this.grid.spacing.x / -2.0)
    brick.translateY(this.grid.spacing.y / -2.0)
    brick.translateZ(this.grid.spacing.z / -2.0)

    // move to world position
    brick.translateX(worldBrickPosition.x)
    brick.translateY(worldBrickPosition.y)
    brick.translateZ(worldBrickPosition.z)

    return brick
  }

  getBrickBox (boxDimensions, material) {
    const geometry = this._getBrickGeometry(boxDimensions)
    const box = new THREE.Mesh(geometry, material)
    box.dimensions = boxDimensions
    return box
  }

  _getBrickGeometry (brickDimensions, worldBrickSize) {
    // returns a box geometry for the given dimensions

    if (worldBrickSize == null) {
      worldBrickSize = {
        x: brickDimensions.x * this.grid.spacing.x,
        y: brickDimensions.y * this.grid.spacing.y,
        z: brickDimensions.z * this.grid.spacing.z,
      }
    }

    const dimensionsHash = this._getHash(brickDimensions)
    if (this.brickGeometryCache[dimensionsHash] != null) {
      return this.brickGeometryCache[dimensionsHash]
    }

    const brickGeometry = new THREE.BoxGeometry(
      worldBrickSize.x,
      worldBrickSize.y,
      worldBrickSize.z,
    )

    this.brickGeometryCache[dimensionsHash] = brickGeometry
    return brickGeometry
  }

  _getStudsGeometry (brickDimensions, worldBrickSize, cache, geometry) {
    // returns studs for the given brick size

    const dimensionsHash = this._getHash(brickDimensions)
    if (cache[dimensionsHash] != null) {
      return cache[dimensionsHash]
    }

    const studs = new THREE.Geometry()

    for (let xi = 0, end = brickDimensions.x - 1; xi <= end; xi++) {
      for (let yi = 0, end1 = brickDimensions.y - 1; yi <= end1; yi++) {
        const tx = (this.grid.spacing.x * (xi + 0.5)) - (worldBrickSize.x / 2)
        const ty = (this.grid.spacing.y * (yi + 0.5)) - (worldBrickSize.y / 2)
        const tz = (this.grid.spacing.z * brickDimensions.z) - (worldBrickSize.z / 2)

        const translation = new THREE.Matrix4()
        translation.makeTranslation(tx, ty, tz)

        studs.merge(geometry, translation)
      }
    }

    const bufferGeometry = new THREE.BufferGeometry()
    bufferGeometry.fromGeometry(studs)

    cache[dimensionsHash] = bufferGeometry
    return bufferGeometry
  }

  _getPlaneGeometry (brickDimensions, worldBrickSize) {
    // returns studs for the given brick size

    const dimensionsHash = this._getHash(brickDimensions)
    if (this.planeGeometryCache[dimensionsHash] != null) {
      return this.planeGeometryCache[dimensionsHash]
    }

    const studs = new THREE.PlaneBufferGeometry(
      this.grid.spacing.x * brickDimensions.x,
      this.grid.spacing.y * brickDimensions.y,
    )

    const tz = (this.grid.spacing.z * brickDimensions.z) - (worldBrickSize.z / 2)
    const translation = new THREE.Matrix4()
    translation.makeTranslation(0, 0, tz)
    studs.applyMatrix(translation)

    this.planeGeometryCache[dimensionsHash] = studs
    return studs
  }

  _getHash (dimensions) {
    return dimensions.x + "-" + dimensions.y + "-" + dimensions.z
  }
}
