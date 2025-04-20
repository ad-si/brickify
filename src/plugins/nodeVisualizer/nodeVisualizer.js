import threeHelper from "../../client/threeHelper.js"
import BrickVisualization from "./visualization/brickVisualization.js"
import ModelVisualization from "./modelVisualization.js"
import interactionHelper from "../../client/interactionHelper.js"
import RenderTargetHelper from "../../client/rendering/renderTargetHelper.js"
import stencilBits from "../../client/rendering/stencilBits.js"
import Coloring from "./visualization/Coloring.js"
import ColorMultPart from "../../client/rendering/shader/ColorMultPart.js"
import ExpandBlackPart from "../../client/rendering/shader/ExpandBlackPart.js"
import PrintingTimeEstimator from "./printingTimeEstimator.js"

/*
 * @class NodeVisualizer
 */
export default class NodeVisualizer {
  constructor () {
    // rendering properties
    this.init = this.init.bind(this)
    this.init3d = this.init3d.bind(this)
    this.onPaint = this.onPaint.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
    this.objectModified = this.objectModified.bind(this)
    this.onNodeAdd = this.onNodeAdd.bind(this)
    this.onNodeRemove = this.onNodeRemove.bind(this)
    this.onNodeSelect = this.onNodeSelect.bind(this)
    this.onNodeDeselect = this.onNodeDeselect.bind(this)
    this._zoomToNode = this._zoomToNode.bind(this)
    this._initializeData = this._initializeData.bind(this)
    this._getCachedData = this._getCachedData.bind(this)
    this.createNodeDataStructure = this.createNodeDataStructure.bind(this)
    this.setDisplayMode = this.setDisplayMode.bind(this)
    this.getDisplayMode = this.getDisplayMode.bind(this)
    this._applyStabilityView = this._applyStabilityView.bind(this)
    this._applyBuildMode = this._applyBuildMode.bind(this)
    this.getNumberOfBuildLayers = this.getNumberOfBuildLayers.bind(this)
    this.showBuildLayer = this.showBuildLayer.bind(this)
    this._updateBrickCount = this._updateBrickCount.bind(this)
    this._updatePrintTime = this._updatePrintTime.bind(this)
    this._updateQuickPrintTime = this._updateQuickPrintTime.bind(this)
    this._showCsg = this._showCsg.bind(this)
    this.pointerOverModel = this.pointerOverModel.bind(this)
    this._getPointerIntersections = this._getPointerIntersections.bind(this)
    this.getBrickThreeNode = this.getBrickThreeNode.bind(this)
    this.brickVisualizations = {}
    this.fidelity = 0
  }

  init (bundle) {
    this.bundle = bundle
    this.coloring = new Coloring(this.bundle.globalConfig)

    this.objectColorMult = new THREE.Vector3(
      this.bundle.globalConfig.colors.objectColorMult,
      this.bundle.globalConfig.colors.objectColorMult,
      this.bundle.globalConfig.colors.objectColorMult,
    )
    this.objectShadowColorMult = new THREE.Vector3(
      this.bundle.globalConfig.colors.objectShadowColorMult,
      this.bundle.globalConfig.colors.objectShadowColorMult,
      this.bundle.globalConfig.colors.objectShadowColorMult,
    )
    this.brickShadowOpacity = this.bundle.globalConfig.colors.brickShadowOpacity
    this.objectOpacity = this.bundle.globalConfig.colors.modelOpacity
    this.objectShadowOpacity = this.bundle.globalConfig.colors.modelShadowOpacity

    if (this.bundle.globalConfig.buildUi) {
      this.brickCounter = $("#brickCount")
      return this.timeEstimate = $("#timeEstimate")
    }
  }

  init3d (threeJsRootNode) {
    this.threeJsRootNode = threeJsRootNode
    this.usePipeline = false

    // Voxels / Bricks are rendered as a first render pass
    this.brickScene = this.bundle.renderer.getDefaultScene()
    this.brickRootNode = new THREE.Object3D()
    this.threeJsRootNode.add(this.brickRootNode)

    // Objects are rendered in the 2nd / 3rd render pass
    this.objectsScene = this.bundle.renderer.getDefaultScene()
    this.objectsRootNode = new THREE.Object3D()
    this.threeJsRootNode.add(this.objectsRootNode)

    // LegoShadow is rendered as a 3rd rendering pass
    this.brickShadowScene = this.bundle.renderer.getDefaultScene()
    this.brickShadowRootNode = new THREE.Object3D()
    return this.threeJsRootNode.add(this.brickShadowRootNode)
  }

  onPaint (threeRenderer1, camera, target) {
    this.threeRenderer = threeRenderer1
    const {
      threeRenderer,
    } = this

    // recreate textures if either they haven't been generated yet or
    // the screen size has changed
    if (!(this.renderTargetsInitialized &&
    RenderTargetHelper.renderTargetHasRightSize(
      this.brickSceneTarget.renderTarget, threeRenderer,
    ))) {
      // bricks
      if (this.brickSceneTarget != null) {
        RenderTargetHelper.deleteRenderTarget(this.brickSceneTarget, this.threeRenderer)
      }

      this.brickSceneTarget = RenderTargetHelper.createRenderTarget(
        threeRenderer,
        null,
        null,
        1.0,
      )

      // object target
      if (this.objectsSceneTarget != null) {
        RenderTargetHelper.deleteRenderTarget(this.objectsSceneTarget, this.threeRenderer)
      }

      this.objectsSceneTarget = RenderTargetHelper.createRenderTarget(
        threeRenderer,
        [new ExpandBlackPart(2), new ColorMultPart()],
        {colorMult: {type: "v3", value: new THREE.Vector3(1, 1, 1)}},
        this.objectOpacity,
      )

      // brick shadow target
      if (this.brickShadowSceneTarget != null) {
        RenderTargetHelper.deleteRenderTarget(
          this.brickShadowSceneTarget, this.threeRenderer,
        )
      }

      this.brickShadowSceneTarget = RenderTargetHelper.createRenderTarget(
        threeRenderer,
        [new ExpandBlackPart(2)],
        null,
        this.brickShadowOpacity,
      )

      this.renderTargetsInitialized = true
    }

    // First render pass: render Bricks & Voxels
    threeRenderer.render(this.brickScene, camera, this.brickSceneTarget.renderTarget, true)

    // Second pass: render object
    threeRenderer.render(
      this.objectsScene, camera, this.objectsSceneTarget.renderTarget, true,
    )

    // Third pass: render shadows
    threeRenderer.render(
      this.brickShadowScene, camera, this.brickShadowSceneTarget.renderTarget, true,
    )

    // finally render everything (on quads) on screen
    const gl = threeRenderer.context

    // everything that is visible lego gets the first bit set
    gl.enable(gl.STENCIL_TEST)
    gl.stencilFunc(gl.ALWAYS, stencilBits.legoMask, 0xFF)
    gl.stencilOp(gl.ZERO, gl.ZERO, gl.REPLACE)
    gl.stencilMask(0xFF)

    // bricks
    threeRenderer.render(this.brickSceneTarget.quadScene, camera, target, false)

    // everything that is 3d model and hidden gets the third bit set
    // every visible part of the 3d model gets the second bit set
    // (via increase and not being allowed to remove the first bit)
    gl.stencilFunc(gl.ALWAYS, stencilBits.hiddenObjectMask, 0xFF)
    gl.stencilOp(gl.KEEP, gl.REPLACE, gl.INCR)
    gl.stencilMask(stencilBits.visibleObjectMask | stencilBits.hiddenObjectMask)

    // render visible parts
    threeRenderer.render(this.objectsSceneTarget.quadScene, camera, target, false)

    // render invisible parts (object behind lego bricks)
    if ((this.visualizationMode != null) && (this.visualizationMode === "printBrush")) {
      // Adjust object material to be dark and more transparent
      const blendMat = this.objectsSceneTarget.blendingMaterial
      blendMat.uniforms.colorMult.value = this.objectShadowColorMult
      blendMat.uniforms.opacity.value = this.objectShadowOpacity

      // Only render where there is hidden 3d model
      gl.stencilFunc(
        gl.EQUAL, stencilBits.hiddenObjectMask, stencilBits.hiddenObjectMask,
      )
      gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)

      gl.disable(gl.DEPTH_TEST)
      threeRenderer.render(this.objectsSceneTarget.quadScene, camera, target, false)
      gl.enable(gl.DEPTH_TEST)

      // Reset material to non-shadow properties
      blendMat.uniforms.opacity.value = this.objectOpacity
      blendMat.uniforms.colorMult.value = this.objectColorMult
    }

    // everything shadowy gets the fourth bit set
    gl.stencilFunc(gl.ALWAYS, 0xFF, 0xFF)
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
    gl.stencilMask(stencilBits.visibleShadowMask)

    // render this-could-be-lego-shadows and brush highlight
    threeRenderer.render(this.brickShadowSceneTarget.quadScene, camera, target, false)

    return gl.disable(gl.STENCIL_TEST)
  }

  setFidelity (fidelityLevel, availableLevels) {
    // Determine whether to use the pipeline or not
    if (fidelityLevel >= availableLevels.indexOf("PipelineLow")) {
      if (!this.usePipeline) {
        this.usePipeline = true

        // move all subnodes to the pipeline scenes
        this.threeJsRootNode.remove(this.brickRootNode)
        this.threeJsRootNode.remove(this.brickShadowRootNode)
        this.threeJsRootNode.remove(this.objectsRootNode)

        this.brickScene.add(this.brickRootNode)
        this.objectsScene.add(this.objectsRootNode)
        this.brickShadowScene.add(this.brickShadowRootNode)

        // change material properties
        this.coloring.setPipelineMode(true)
      }
    }
    else {
      if (this.usePipeline) {
        this.usePipeline = false

        // move all subnodes to conventional rendering
        this.brickScene.remove(this.brickRootNode)
        this.brickShadowScene.remove(this.brickShadowRootNode)
        this.objectsScene.remove(this.objectsRootNode)

        this.threeJsRootNode.add(this.brickRootNode)
        this.threeJsRootNode.add(this.objectsRootNode)
        this.threeJsRootNode.add(this.brickShadowRootNode)

        // change material properties
        this.coloring.setPipelineMode(false)
      }
    }

    if (fidelityLevel >= availableLevels.indexOf("PipelineHigh")) {
      this.fidelity = 2
    }
    else if (fidelityLevel > availableLevels.indexOf("DefaultMedium")) {
      this.fidelity = 1
    }
    else {
      this.fidelity = 0
    }

    return (() => {
      const result = []
      for (const nodeId in this.brickVisualizations) {
        const brickVisualization = this.brickVisualizations[nodeId]
        result.push(brickVisualization.setFidelity(this.fidelity))
      }
      return result
    })()
  }

  // called by newBrickator when an object's data structure is modified
  objectModified (node, newBrickatorData) {
    return this._getCachedData(node)
      .then(cachedData => {
        if (!cachedData.initialized) {
          this._initializeData(node, cachedData, newBrickatorData)
        }

        // visualization
        cachedData.brickVisualization.updateVisualization()
        cachedData.brickVisualization.showVoxelAndBricks()

        // brick count / printing time
        this._updateBrickCount(cachedData.brickVisualization.grid.getAllBricks())
        return this._updateQuickPrintTime(
          cachedData.brickVisualization.grid.getDisabledVoxels(),
          cachedData.brickVisualization.grid.spacing,
        )
      })
  }

  onNodeAdd (node) {
    // link other plugins
    if (this.newBrickator == null) {
      this.newBrickator = this.bundle.getPlugin("newBrickator")
    }

    // create visible node and zoom to it
    return this._getCachedData(node)
      .then(cachedData => {
        cachedData.modelVisualization.createVisualization()
        return cachedData.modelVisualization.afterCreation()
          .then(() => {
            const solid = cachedData.modelVisualization.getSolid()
            if (solid != null) {
              return this._zoomToNode(solid)
            }
          })
      })
  }

  onNodeRemove (node) {
    this.brickRootNode.remove(threeHelper.find(node, this.brickRootNode))
    this.brickShadowRootNode.remove(threeHelper.find(node, this.brickShadowRootNode))
    this.objectsRootNode.remove(threeHelper.find(node, this.objectsRootNode))
    return delete this.brickVisualizations[node.id]
  }

  onNodeSelect (selectedNode) {
    this.selectedNode = selectedNode
  }

  onNodeDeselect () {
    return this.selectedNode = null
  }

  _zoomToNode (threeNode) {
    return this.bundle.renderer.zoomToNode(threeNode)
  }

  // initialize visualization with data from newBrickator
  // change solid renderer appearance
  _initializeData (node, visualizationData, newBrickatorData) {
    // init node visualization
    visualizationData.brickVisualization.initialize(newBrickatorData.grid)
    return visualizationData.initialized = true
  }

  // returns the node visualization or creates one
  _getCachedData (selectedNode) {
    return selectedNode.getPluginData("brickVisualizer")
      .then(data => {
        if (data != null) {
          return data
        }
        else {
          data = this.createNodeDataStructure(selectedNode)
          selectedNode.storePluginData("brickVisualizer", data, true)
          return data
        }
      })
  }

  // creates visualization data structures
  createNodeDataStructure (node) {
    const brickThreeNode = new THREE.Object3D()
    const brickShadowThreeNode = new THREE.Object3D()
    const modelThreeNode = new THREE.Object3D()

    this.brickRootNode.add(brickThreeNode)
    this.brickShadowRootNode.add(brickShadowThreeNode)
    this.objectsRootNode.add(modelThreeNode)

    threeHelper.link(node, brickThreeNode)
    threeHelper.link(node, brickShadowThreeNode)
    threeHelper.link(node, modelThreeNode)

    const brickVisualization = new BrickVisualization(
      this.bundle, brickThreeNode, brickShadowThreeNode, this.coloring, this.fidelity,
    )
    this.brickVisualizations[node.id] = brickVisualization

    const data = {
      initialized: false,
      node,
      brickThreeNode,
      brickShadowThreeNode,
      modelThreeNode,
      brickVisualization,
      modelVisualization: new ModelVisualization(
        this.bundle.globalConfig, node, modelThreeNode, this.coloring,
      ),
    }

    return data
  }

  /*
   * Sets the overall display mode
   * @param {Node} selectedNode the currently selected node
   * @param {String} mode the mode: 'legoBrush'/'printBrush'/'stability'/'build'
   */
  setDisplayMode (selectedNode, visualizationMode) {
    this.visualizationMode = visualizationMode
    if (selectedNode == null) {
      return
    }

    return this._getCachedData(selectedNode)
      .then(cachedData => {
        switch (this.visualizationMode) {
          case "legoBrush":
            this._resetStabilityView(cachedData)
            this._resetBuildMode(cachedData)
            return this._applyLegoBrushMode(cachedData)
          case "printBrush":
            this._resetStabilityView(cachedData)
            this._resetBuildMode(cachedData)
            return this._applyPrintBrushMode(cachedData)
          case "stability":
            this._resetBuildMode(cachedData)
            return this._applyStabilityView(cachedData)
          case "build":
            this._resetStabilityView(cachedData)
            return this._applyBuildMode(cachedData)
          default:
            this._resetStabilityView(cachedData)
            return this._resetBuildMode(cachedData)
        }
      })
  }

  getDisplayMode () {
    return this.visualizationMode
  }

  _applyLegoBrushMode (cachedData) {
    cachedData.brickVisualization.updateVisualization()
    cachedData.brickVisualization.showVoxelAndBricks()
    cachedData.brickVisualization.setPossibleLegoBoxVisibility(true)
    return cachedData.modelVisualization.setShadowVisibility(false)
  }

  _applyPrintBrushMode (cachedData) {
    cachedData.brickVisualization.updateVisualization()
    cachedData.brickVisualization.showVoxelAndBricks()
    cachedData.brickVisualization.setPossibleLegoBoxVisibility(false)
    return cachedData.modelVisualization.setShadowVisibility(true)
  }

  _applyStabilityView (cachedData) {
    cachedData.stabilityViewEnabled  = true

    this._showCsg(cachedData)
      .then(() => // change coloring to stability coloring
        cachedData.brickVisualization.setStabilityView(true))

    return cachedData.modelVisualization.setNodeVisibility(false)
  }

  _resetStabilityView (cachedData) {
    if (cachedData.stabilityViewEnabled) {
      cachedData.brickVisualization.setStabilityView(false)
      cachedData.brickVisualization.hideCsg()
      cachedData.modelVisualization.setNodeVisibility(true)
      return cachedData.stabilityViewEnabled = false
    }
  }

  _applyBuildMode (cachedData) {
    // Show bricks and csg
    cachedData.brickVisualization.setPossibleLegoBoxVisibility(false)
    cachedData.brickVisualization.setHighlightVoxelVisibility(false)

    this._showCsg(cachedData)

    return cachedData.modelVisualization.setNodeVisibility(false)
  }

  _resetBuildMode (cachedData) {
    cachedData.brickVisualization.setHighlightVoxelVisibility(true)
    cachedData.brickVisualization.hideCsg()
    cachedData.brickVisualization.showAllBrickLayers()
    return cachedData.modelVisualization.setNodeVisibility(true)
  }

  // Returns the amount of LEGO-Layers that can be shown in build mode.
  // Layers without bricks are discarded
  getNumberOfBuildLayers (selectedNode) {
    return this._getCachedData(selectedNode)
      .then(cachedData => cachedData.brickVisualization.getNumberOfBuildLayers())
  }

  // when build mode is enabled, this tells the visualization to show
  // bricks up to the specified layer
  showBuildLayer (selectedNode, layer) {

    // Start counting at 0 internally
    layer--

    return this._getCachedData(selectedNode)
      .then(cachedData => cachedData.brickVisualization.showBrickLayer(layer))
  }

  _updateBrickCount (bricks) {
    return this.brickCounter != null ? this.brickCounter.text(bricks.size) : undefined
  }

  _updatePrintTime (csg) {
    if (csg != null) {
      let time = PrintingTimeEstimator.getPrintingTimeEstimate(csg)
      time = Math.round(time)
      return this.timeEstimate != null ? this.timeEstimate.text(time) : undefined
    }
    else {
      return this.timeEstimate != null ? this.timeEstimate.text(0) : undefined
    }
  }

  _updateQuickPrintTime (voxels, spacing) {
    let time = PrintingTimeEstimator.getPrintingTimeEstimateForVoxels(voxels, spacing)
    time = Math.round(time)
    return this.timeEstimate != null ? this.timeEstimate.text(time) : undefined
  }

  _showCsg (cachedData) {
    if (this.csg == null) {
      this.csg = this.bundle.getPlugin("csg")
    }
    if (this.csg == null) {
      return Promise.resolve()
    }

    const options = {
      addStuds: true,
      minimalPrintVolume: this.bundle.globalConfig.minimalPrintVolume,
    }

    return this.csg.getCSG(cachedData.node, options)
      .then(csg => {
        cachedData.brickVisualization.showCsg(csg)
        return this._updatePrintTime(csg)
      })
  }

  // check whether the pointer is over a model/brick visualization
  pointerOverModel (event, ignoreInvisible) {
    if (ignoreInvisible == null) {
      ignoreInvisible = true
    }
    const intersections = this._getPointerIntersections(event)

    if (!ignoreInvisible) {
      return intersections.length > 0
    }
    const visibleIntersections = intersections.filter((intersection) => {
      let {
        object,
      } = intersection
      while (object != null) {
        if (!object.visible) {
          return false
        }
        object = object.parent
      }
      return true
    })

    return visibleIntersections.length > 0
  }

  _getPointerIntersections (event) {
    if (this.usePipeline) {
      const modelIntersections = interactionHelper.getIntersections(
        event, this.bundle.renderer, this.objectsRootNode.children,
      )
      if (modelIntersections.length > 0) {
        return modelIntersections
      }

      const brickIntersections = interactionHelper.getIntersections(
        event, this.bundle.renderer, this.brickRootNode.children,
      )
      return brickIntersections
    }
    else {
      const mixedIntersections = interactionHelper.getIntersections(
        event, this.bundle.renderer, this.threeJsRootNode.children,
      )
      return mixedIntersections
    }
  }

  getBrickThreeNode (node) {
    return this._getCachedData(node)
      .then(cachedData => cachedData.brickThreeNode)
  }
}
