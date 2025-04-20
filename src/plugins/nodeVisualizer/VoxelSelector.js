import THREE from "three"

import interactionHelper from "../../client/interactionHelper.js"

/*
 * @class VoxelSelector
 */
export default class VoxelSelector {
  constructor (brickVisualization) {
    this.getAllVoxels = this.getAllVoxels.bind(this)
    this.getVoxels = this.getVoxels.bind(this)
    this.getVoxel = this.getVoxel.bind(this)
    this.getBrushSize = this.getBrushSize.bind(this)
    this.clearSelection = this.clearSelection.bind(this)
    this.touch = this.touch.bind(this)
    this.renderer = brickVisualization.bundle.renderer
    this.grid = brickVisualization.grid
    this.voxelWireframe = brickVisualization.voxelWireframe
    this.level = undefined

    this.touchedVoxels = []

    this.geometryCreator = brickVisualization.geometryCreator
  }

  getAllVoxels () {
    const voxels = []
    this.grid.forEachVoxel(voxel => voxels.push(voxel))
    return voxels
  }

  /*
   * Gets the voxels to be processed in the given event.
   * @param {Object} event usually a mouse or tap or pointer event
   * @param {Object} options some options for the voxels to be found
   * @param {Boolean} [options.bigBrush=true] should a big brush be used?
   * @param {String} [options.type='lego'] 'lego' or '3d'
   */
  getVoxels (event, options) {
    const type = options.type || "lego"

    const mainVoxel = this.getVoxel(event, options)
    if ((mainVoxel != null ? mainVoxel.position : undefined) == null) {
      return null
    }

    const size = this.getBrushSize(options.bigBrush)
    const gridEntries = this.grid.getSurrounding(mainVoxel.position, size)
    const voxels = gridEntries
      .filter(voxel => this._hasType(voxel, type))
      .filter(voxel => !Array.from(this.touchedVoxels)
        .includes(voxel))
    this.touchedVoxels = this.touchedVoxels.concat(voxels)
    if (options.bigBrush) {
      this.level = mainVoxel.position.z
    }
    return voxels
  }

  /*
   * Gets the voxel to be processed in the given event.
   * @param {Object} event usually a mouse or tap or pointer event
   * @param {Object} options some options for the voxel to be found
   * @param {String} [options.type='lego'] 'lego' or '3d'
   */
  getVoxel (event, options) {
    const type = options.type || "lego"

    const intersections = this._getIntersections(event)
    const voxels = intersections.map(obj => obj.voxel)

    if (this.level != null) {
      return this._getLeveledVoxel(event, voxels)
    }

    let voxel = this._getFrontierVoxel(voxels, type)
    // We found a frontier voxel but there is no valid previous voxel:
    if (voxel || (voxel === null)) {
      return voxel
    }
    // We have not even found a frontier voxel: (voxel is undefined)
    if (type === "3d") {
      if (voxel == null) {
        voxel = this._getBaseplateVoxel(event, type)
      }
      if (voxel == null) {
        voxel = this._getMiddleVoxel(event)
      }
    }
    return voxel
  }

  _getLeveledVoxel (event, voxels) {
    const voxel =  voxels.find(voxel => voxel.position.z === this.level)
    if (voxel) {
      return voxel
    }

    const levelWorldPosition = this.grid.mapVoxelToWorld({x: 0, y: 0, z: this.level}).z
    const position = interactionHelper.getPlanePosition(
      event,
      this.renderer,
      levelWorldPosition,
    )

    const voxelCoords = this.grid.mapGridToVoxel(this.grid.mapWorldToGrid(position))
    const pseudoVoxel =
      {position: voxelCoords}
    return pseudoVoxel
  }

  _getFrontierVoxel (voxels, type) {
    const lastTouched = this.touchedVoxels.slice(-2)
    const frontier = voxels.findIndex(voxel => voxel.isLego())
    if (!(frontier > -1)) {
      return undefined
    }

    const prevVoxel = voxels[frontier - 1]
    const frontierVoxel = voxels[frontier]

    // The frontier lego voxel is the first voxel in the intersection
    // If we want lego, use it, if we want 3d, there is nothing to be found
    if (prevVoxel === undefined) {
      if (type === "lego") {
        return frontierVoxel
      }
      if (type === "3d") {
        return null
      }
    }

    if (((type === "lego") && !Array.from(lastTouched)
      .includes(prevVoxel)) ||
    ((type === "3d") && Array.from(lastTouched)
      .includes(frontierVoxel))) {
      return frontierVoxel
    }
    else {
      return prevVoxel
    }
  }

  _getBaseplateVoxel (event, type) {
    const baseplatePos = interactionHelper.getGridPosition(event, this.renderer)
    const voxelPos = this.grid.mapGridToVoxel(this.grid.mapWorldToGrid(baseplatePos))
    const voxel = this.grid.getVoxel(voxelPos.x, voxelPos.y, voxelPos.z)
    if (voxel == null) {
      return undefined
    }

    if (this._hasType(voxel, type)) {
      return voxel
    }
    else {
      return null
    }
  }

  _getMiddleVoxel (event) {
    const modelIntersects = this.voxelWireframe.intersectRay(event)
    if (!(modelIntersects.length >= 2)) {
      return undefined
    }

    const start = modelIntersects[0].point
    const end = modelIntersects[1].point

    const middle = new THREE.Vector3(
      (start.x + end.x) / 2,
      (start.y + end.y) / 2,
      (start.z + end.z) / 2,
    )

    const revTransform = new THREE.Matrix4()
    revTransform.getInverse(this.renderer.scene.matrix)
    middle.applyMatrix4(revTransform)

    const voxelPos = this.grid.mapGridToVoxel(this.grid.mapWorldToGrid(middle))
    return this.grid.getVoxel(voxelPos.x, voxelPos.y, voxelPos.z)
  }

  _getIntersections (event) {
    const rayDirection = interactionHelper.calculateRay(event, this.renderer)
    const rayOrigin = this.renderer.getCamera().position.clone()

    return this.grid.intersectVoxels(rayOrigin, rayDirection)
  }

  _hasType (voxel, type) {
    return (voxel.isLego() && (type === "lego")) ||
      (!voxel.isLego() && (type === "3d"))
  }

  /*
   * Gets the brush size to be used depending on the `bigBrush` flag. The big
   * brush size is set to a reasonable size according to the model size.
   * @param {Boolean} bigBrush should a big Brush be used?
   */
  getBrushSize (bigBrush) {
    if (!bigBrush) {
      return {x: 1, y: 1, z: 1}
    }
    const length = Math.sqrt(Math.max(
      this.grid.getNumVoxelsX(),
      this.grid.getNumVoxelsY(),
      this.grid.getNumVoxelsZ(),
    ),
    )

    let height = Math.round(length * this.grid.heightRatio)
    let size = Math.round(length)

    // Make sure that the size is odd. This is needed because the big brush
    // stretches over the middle voxel and the same number of voxels in all
    // directions (+ and -) -> 1 + 2n -> we need an odd number.
    if ((size % 2) === 0) {
      size += 1
    }
    if ((height % 2) === 0) {
      height += 1
    }

    return {x: size, y: size, z: height}
  }

  /*
   * Clears the current collection of touched voxels.
   * @return {Array<BrickObject>} the touched voxels before clearing
   */
  clearSelection () {
    const tmp = this.touchedVoxels
    this.touchedVoxels = []
    this.level = undefined
    return tmp
  }

  touch (voxel) {
    return this.touchedVoxels.push(voxel)
  }
}
