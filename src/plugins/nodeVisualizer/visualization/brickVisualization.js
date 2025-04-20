import THREE from "three"

import GeometryCreator from "./GeometryCreator.js"
import StabilityColoring from "./StabilityColoring.js"
import VoxelWireframe from "./VoxelWireframe.js"
import VoxelSelector from "../VoxelSelector.js"

/*
 * This class provides visualization for Voxels and Bricks
 * @class BrickVisualization
 */
export default class BrickVisualization {
  constructor (bundle,  brickThreeNode, brickShadowThreeNode,
    defaultColoring, fidelity) {

    this.initialize = this.initialize.bind(this)
    this.showCsg = this.showCsg.bind(this)
    this.hideCsg = this.hideCsg.bind(this)
    this.hideVoxelAndBricks = this.hideVoxelAndBricks.bind(this)
    this.showVoxelAndBricks = this.showVoxelAndBricks.bind(this)
    this.updateVisualization = this.updateVisualization.bind(this)
    this.setPossibleLegoBoxVisibility = this.setPossibleLegoBoxVisibility.bind(this)
    this.setStabilityView = this.setStabilityView.bind(this)
    this.showBrickLayer = this.showBrickLayer.bind(this)
    this.showAllBrickLayers = this.showAllBrickLayers.bind(this)
    this.getNumberOfVisibleLayers = this.getNumberOfVisibleLayers.bind(this)
    this.getNumberOfBuildLayers = this.getNumberOfBuildLayers.bind(this)
    this._getBuildLayerModifier = this._getBuildLayerModifier.bind(this)
    this._getVisibleLayers = this._getVisibleLayers.bind(this)
    this.highlightVoxel = this.highlightVoxel.bind(this)
    this._highlightBigBrush = this._highlightBigBrush.bind(this)
    this.unhighlightBigBrush = this.unhighlightBigBrush.bind(this)
    this.makeVoxel3dPrinted = this.makeVoxel3dPrinted.bind(this)
    this.makeAllVoxels3dPrinted = this.makeAllVoxels3dPrinted.bind(this)
    this.resetTouchedVoxelsToLego = this.resetTouchedVoxelsToLego.bind(this)
    this.makeVoxelLego = this.makeVoxelLego.bind(this)
    this.makeAllVoxelsLego = this.makeAllVoxelsLego.bind(this)
    this.resetTouchedVoxelsTo3dPrinted = this.resetTouchedVoxelsTo3dPrinted.bind(this)
    this.updateModifiedVoxels = this.updateModifiedVoxels.bind(this)
    this.setHighlightVoxelVisibility = this.setHighlightVoxelVisibility.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
    this.bundle = bundle
    this.brickThreeNode = brickThreeNode
    this.brickShadowThreeNode = brickShadowThreeNode
    this.defaultColoring = defaultColoring
    this.fidelity = fidelity
    this.csgSubnode = new THREE.Object3D()
    this.brickThreeNode.add(this.csgSubnode)

    this.bricksSubnode = new THREE.Object3D()
    this.temporaryVoxels = new THREE.Object3D()
    this.brickThreeNode.add(this.bricksSubnode)
    this.brickThreeNode.add(this.temporaryVoxels)

    this.stabilityColoring = new StabilityColoring()

    this.printVoxels = []

    this.isStabilityView = false
    this._highlightVoxelVisibility = true
  }

  initialize (grid) {
    this.grid = grid
    this.voxelWireframe = new VoxelWireframe(
      this.bundle, this.grid, this.brickShadowThreeNode, this.defaultColoring,
    )
    this.geometryCreator = new GeometryCreator(this.bundle.globalConfig, this.grid)
    this.voxelSelector = new VoxelSelector(this)

    this._highlightVoxel = this.geometryCreator.getBrick(
      {x: 0, y: 0, z: 0},
      {x: 1, y: 1, z: 1},
      this.defaultColoring.getHighlightMaterial("3d").voxel,
      this.fidelity,
    )
    this._highlightVoxel.visible = false

    return this.brickThreeNode.add(this._highlightVoxel)
  }

  showCsg (newCsgGeometry) {
    this.csgSubnode.children = []
    if (newCsgGeometry == null) {
      this.csgSubnode.visible = false
    }

    for (const geometry of Array.from(newCsgGeometry)) {
      const csgMesh = new THREE.Mesh(geometry, this.defaultColoring.csgMaterial)
      this.csgSubnode.add(csgMesh)
    }

    return this.csgSubnode.visible = true
  }

  hideCsg () {
    return this.csgSubnode.visible = false
  }

  hideVoxelAndBricks () {
    return this.bricksSubnode.visible = false
  }

  showVoxelAndBricks () {
    return this.bricksSubnode.visible  = true
  }

  // Updates brick and voxel visualization
  updateVisualization (coloring, recreate) {
    // Delete temporary voxels
    let brick; let brickLayer; let layer; let layerObject; let materials; let visualBrick; let z
    let asc; let end
    if (coloring == null) {
      coloring = this.defaultColoring
    }
    if (recreate == null) {
      recreate = false
    }
    this.temporaryVoxels.children = []

    if (recreate) {
      this.bricksSubnode.children = []
    }
    else {
      // Throw out all visual bricks that have no valid linked brick
      for (layer of Array.from(this.bricksSubnode.children)) {
        const deletionList = []
        for (visualBrick of Array.from(layer.children)) {
          if ((visualBrick.brick == null) || !visualBrick.brick.isValid()) {
            deletionList.push(visualBrick)
          }
        }

        for (const delBrick of Array.from(deletionList)) {
          // Remove from scenegraph
          layer.remove(delBrick)
          // Delete reference from datastructure brick
          if (delBrick.brick != null) {
            delBrick.brick.setVisualBrick(null)
          }
        }
      }
    }

    // Recreate visible bricks for all bricks in the datastructure that
    // have no linked brick

    // Sort layerwise for build view
    const brickLayers = []
    let maxZ = 0

    this.grid.getAllBricks()
      .forEach(brick => {
        const {
          z,
        } = brick.getPosition()
        maxZ = Math.max(z, maxZ)
        if (brickLayers[z] == null) {
          brickLayers[z] = []
        }

        if (!recreate && ((brick.getVisualBrick() == null))) {
          brickLayers[z].push(brick)
        }
        if (brick.getVisualBrick() != null) {
          brick.getVisualBrick().visible = true
          return brick.getVisualBrick().hasBeenSplit = false
        }
      })

    // Create three layer object if it does not exist
    for (z = 0, end = maxZ, asc = end >= 0; asc ? z <= end : z >= end; asc ? z++ : z--) {
      if (this.bricksSubnode.children[z] == null) {
        layerObject = new THREE.Object3D()
        this.bricksSubnode.add(layerObject)
      }
    }

    for (z in brickLayers) {
      brickLayer = brickLayers[z]
      z = Number(z)
      layerObject = this.bricksSubnode.children[z]

      for (brick of Array.from(brickLayer)) {
        // Create visual brick
        materials = coloring.getMaterialsForBrick(brick)
        const threeBrick = this.geometryCreator.getBrick(
          brick.getPosition(),
          brick.getSize(),
          materials,
          this.fidelity,
        )

        // Link data <-> visuals
        brick.setVisualBrick(threeBrick)

        // Add to scene graph
        layerObject.add(threeBrick)
      }
    }

    // Set stud visibility in second pass so that visibility of
    // all bricks in all layers is in the correct state
    for (z in brickLayers) {
      brickLayer = brickLayers[z]
      for (brick of Array.from(brickLayer)) {
        this._setStudVisibility(brick)
      }
    }

    // If this coloring differs from the last used coloring, go through
    // all visible bricks to update their material
    if (this._oldColoring !== coloring) {
      for (layer of Array.from(this.bricksSubnode.children)) {
        for (visualBrick of Array.from(layer.children)) {
          materials = coloring.getMaterialsForBrick(visualBrick.brick)
          visualBrick.setMaterial(materials)
        }
      }
    }
    this._oldColoring = coloring

    this.unhighlightBigBrush()

    // Show not filled lego shape as outline
    const outlineCoords = this.printVoxels.map(voxel => voxel.position)
    this.voxelWireframe.createWireframe(outlineCoords)

    return this._visibleChildLayers = null
  }

  _setStudVisibility (brick) {
    let showStuds
    const cover = brick.getCover()
    if (cover.isCompletelyCovered) {
      showStuds = false
      cover.coveringBricks.forEach(brick => showStuds = showStuds || !brick.getVisualBrick().visible)
    }
    else {
      showStuds = true
    }

    return brick.getVisualBrick()
      .setStudVisibility(showStuds)
  }

  setPossibleLegoBoxVisibility (isVisible) {
    return this.voxelWireframe.setVisibility(isVisible)
  }

  setStabilityView (enabled) {
    this.isStabilityView = enabled
    const coloring = this.isStabilityView ? this.stabilityColoring : this.defaultColoring
    this.updateVisualization(coloring)

    // Turn off possible lego box and highlight during stability view
    if (enabled) {
      this._legoBoxVisibilityBeforeStability = this.voxelWireframe.isVisible()
      this.voxelWireframe.setVisibility(false)
      return this._highlightVoxel.visible = false
    }
    else {
      return this.voxelWireframe.setVisibility(this._legoBoxVisibilityBeforeStability)
    }
  }

  showBrickLayer (layer) {
    let threeLayer; let visibleBrick
    layer += this._getBuildLayerModifier()

    // Hide highlight when in build mode
    this._highlightVoxel.visible = false
    this.unhighlightBigBrush()

    const visibleLayers = this._getVisibleLayers()
    for (let i = 0, end = visibleLayers.length; i < end; i++) {
      threeLayer = visibleLayers[i]
      if (i <= layer) {
        if (i < layer) {
          this._makeLayerGrayscale(threeLayer)
        }
        else {
          this._makeLayerColored(threeLayer)
        }
        for (visibleBrick of Array.from(threeLayer.children)) {
          visibleBrick.visible = true
        }
      }
      else {
        for (visibleBrick of Array.from(threeLayer.children)) {
          visibleBrick.visible = false
        }
      }
    }

    // Set stud visibility in second pass so that visibility of
    // all bricks in all layers is in the correct state
    for (threeLayer of Array.from(visibleLayers)) {
      for (visibleBrick of Array.from(threeLayer.children)) {
        this._setStudVisibility(visibleBrick.brick)
      }
    }

  }

  _makeLayerGrayscale (layer) {
    return Array.from(layer.children)
      .map((threeBrick) =>
        threeBrick.setGray(true))
  }

  _makeLayerColored (layer) {
    return Array.from(layer.children)
      .map((threeBrick) =>
        threeBrick.setGray(false))
  }

  showAllBrickLayers () {
    return (() => {
      const result = []
      for (const layer of Array.from(this._getVisibleLayers())) {
        layer.visible = true
        result.push(this._makeLayerColored(layer))
      }
      return result
    })()
  }

  getNumberOfVisibleLayers () {
    return this._getVisibleLayers().length
  }

  getNumberOfBuildLayers () {
    let numLayers = this.getNumberOfVisibleLayers()
    numLayers -= this._getBuildLayerModifier()
    return numLayers
  }

  _getBuildLayerModifier () {
    // If there is 3D print below first lego layer, show lego starting
    // with layer 1 and show only 3D print in first instruction layer
    const minLayer = this.grid.getLegoVoxelsZRange().min
    if (minLayer > 0) {
      return -1
    }
    else {
      return 0
    }
  }

  _getVisibleLayers () {
    if (this._visibleChildLayers == null) {
      this._visibleChildLayers = this.bricksSubnode.children.filter(layer => layer.children.length > 0)
    }
    return this._visibleChildLayers
  }

  // Highlights the voxel below mouse and returns it
  highlightVoxel (event, selectedNode, type, bigBrush) {
    // Invert type, because if we are highlighting a 'lego' voxel,
    // we want to display it as 'could be 3d printed'
    let voxelType = "3d"
    if (type === "3d") {
      voxelType = "lego"
    }

    const highlightMaterial = this.defaultColoring.getHighlightMaterial(voxelType)
    const hVoxel = highlightMaterial.voxel
    const hBox = highlightMaterial.box

    const voxel = this.voxelSelector.getVoxel(event, {type})
    if (voxel != null) {
      this._highlightVoxel.visible = true && this._highlightVoxelVisibility
      const worldPos = this.grid.mapVoxelToWorld(voxel.position)
      this._highlightVoxel.position.set(
        worldPos.x, worldPos.y, worldPos.z,
      )
      this._highlightVoxel.setMaterial(hVoxel)
      if (bigBrush) {
        this._highlightBigBrush(voxel, hBox)
      }
    }
    else {
      // Clear highlight if no voxel is below mouse
      this._highlightVoxel.visible = false
      this.unhighlightBigBrush()
    }

    return voxel
  }

  _highlightBigBrush (voxel, material) {
    const size = this.voxelSelector.getBrushSize(true)
    const dimensions = new THREE.Vector3(size.x, size.y, size.z)
    if ((this.bigBrushHighlight == null) ||
    !this.bigBrushHighlight.dimensions.equals(dimensions)) {
      if (this.bigBrushHighlight) {
        this.brickShadowThreeNode.remove(this.bigBrushHighlight)
      }
      this.bigBrushHighlight = this.geometryCreator.getBrickBox(
        dimensions,
        material,
      )
      this.brickShadowThreeNode.add(this.bigBrushHighlight)
    }

    const worldPosition = this.grid.mapVoxelToWorld(voxel.position)
    this.bigBrushHighlight.position.copy(worldPosition)
    this.bigBrushHighlight.material = material
    return this.bigBrushHighlight.visible = true
  }

  unhighlightBigBrush () {
    return this.bigBrushHighlight != null ? this.bigBrushHighlight.visible = false : undefined
  }

  // Makes the voxel below mouse to be 3d printed
  makeVoxel3dPrinted (event, selectedNode, bigBrush) {
    // Hide highlight voxel since it will be made invisible
    this._highlightVoxel.visible = false

    if (bigBrush) {
      const mainVoxel = this.voxelSelector.getVoxel(event, {type: "lego"})
      const mat = this.defaultColoring.getHighlightMaterial("3d")
      if (mainVoxel != null) {
        this._highlightBigBrush(mainVoxel, mat.box)
      }
    }
    const voxels = this.voxelSelector.getVoxels(event, {type: "lego", bigBrush})
    if (!voxels) {
      return null
    }

    for (const voxel of Array.from(voxels)) {
      voxel.make3dPrinted()
      // Show studs of brick below
      const brickBelow = voxel.neighbors.Zm != null ? voxel.neighbors.Zm.brick : undefined
      if (brickBelow) {
        brickBelow.getVisualBrick()
          .setStudVisibility(true)
      }

      // Split visual brick into voxels (only once per brick)
      if (voxel.brick) {
        var visualBrick = voxel.brick.getVisualBrick()
        if (!visualBrick.hasBeenSplit) {
          voxel.brick.forEachVoxel(voxel => {
            // Give this brick a 1x1 stud texture
            visualBrick.materials.textureStuds =
              this.defaultColoring.getTextureMaterialForBrick()
            const temporaryVoxel = this.geometryCreator.getBrick(
              voxel.position,
              {x: 1, y: 1, z: 1},
              visualBrick.materials,
              this.fidelity,
            )
            temporaryVoxel.voxelPosition = voxel.position
            return this.temporaryVoxels.add(temporaryVoxel)
          })
          visualBrick.hasBeenSplit = true
          visualBrick.visible = false
        }
      }
      // Hide visual voxels for 3d printed geometry
      for (const temporaryVoxel of Array.from(this.temporaryVoxels.children)) {
        if (temporaryVoxel.voxelPosition === voxel.position) {
          temporaryVoxel.visible = false
          break
        }
      }
    }

    return voxels
  }

  /*
   * @return {Array} the list of changed voxels
   */
  makeAllVoxels3dPrinted (selectedNode) {
    this.printVoxels = this.voxelSelector.getAllVoxels(selectedNode)
    const legoVoxels = this.printVoxels.filter(voxel => voxel.isLego())
    legoVoxels.map(voxel => voxel.make3dPrinted())
    this.voxelSelector.clearSelection()
    return legoVoxels
  }

  resetTouchedVoxelsToLego () {
    for (const voxel of Array.from(this.voxelSelector.touchedVoxels)) {
      voxel.makeLego()
    }
    return this.voxelSelector.clearSelection()
  }

  // Makes the voxel below mouse to be made out of lego
  makeVoxelLego (event, selectedNode, bigBrush) {
    // Hide highlight
    this._highlightVoxel.visible = false

    if (bigBrush) {
      const mainVoxel = this.voxelSelector.getVoxel(event, {type: "3d"})
      const mat = this.defaultColoring.getHighlightMaterial("lego")
      if (mainVoxel != null) {
        this._highlightBigBrush(mainVoxel, mat.box)
      }
    }
    const voxels = this.voxelSelector.getVoxels(event, {type: "3d", bigBrush})
    if (!voxels) {
      return null
    }

    for (const voxel of Array.from(voxels)) {
      voxel.makeLego()

      // Create a visible temporary voxel at this position
      const temporaryVoxel = this.geometryCreator.getBrick(
        voxel.position,
        {x: 1, y: 1, z: 1},
        this.defaultColoring.getSelectedMaterials(),
        this.fidelity,
      )
      temporaryVoxel.voxelPosition = voxel.position
      this.temporaryVoxels.add(temporaryVoxel)
    }
    return voxels
  }

  /*
   * @return {Array} the list of changed voxels
   */
  makeAllVoxelsLego (selectedNode) {
    const {
      printVoxels,
    } = this
    this.printVoxels = []
    printVoxels.map(voxel => voxel.makeLego())
    this.voxelSelector.clearSelection()
    return printVoxels
  }

  resetTouchedVoxelsTo3dPrinted () {
    for (const voxel of Array.from(this.voxelSelector.touchedVoxels)) {
      voxel.make3dPrinted()
    }
    return this.voxelSelector.clearSelection()
  }

  // Clears the selection and updates the possibleLegoWireframe
  updateModifiedVoxels () {
    this.printVoxels = this.printVoxels
      .concat(this.voxelSelector.touchedVoxels)
      .filter(voxel => !voxel.isLego())
    return this.voxelSelector.clearSelection()
  }

  setHighlightVoxelVisibility (_highlightVoxelVisibility) {
    this._highlightVoxelVisibility = _highlightVoxelVisibility
  }

  setFidelity (fidelity) {
    this.fidelity = fidelity
    if (this._highlightVoxel != null) {
      this._highlightVoxel.setFidelity(this.fidelity)
    }

    for (const voxel of Array.from(this.temporaryVoxels.children)) {
      voxel.setFidelity(this.fidelity)
    }

    return Array.from(this.bricksSubnode.children)
      .map((layer) =>
        Array.from(layer.children)
          .map((threeBrick) =>
            threeBrick.setFidelity(this.fidelity)))
  }
}
