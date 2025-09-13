/**
 * Lego Board Plugin
 *
 * Creates a lego board as a workspace surface to help people align models
 * to the lego grid
 */

import THREE from "three"

import * as RenderTargetHelper from "../../client/rendering/renderTargetHelper.js"
import stencilBits from "../../client/rendering/stencilBits.js"
import DisposableResource from "../../client/rendering/DisposableResource.js"

// Global config will be loaded conditionally

const dimension = 400

export default class LegoBoard {
  // Store the global configuration for later use by init3d
  constructor () {
    this.init3d = this.init3d.bind(this)
    this._initbaseplateBox = this._initbaseplateBox.bind(this)
    this._initStudGeometries = this._initStudGeometries.bind(this)
    this._generateStuds = this._generateStuds.bind(this)
    this._initMaterials = this._initMaterials.bind(this)
    this.on3dUpdate = this.on3dUpdate.bind(this)
    this.onPaint = this.onPaint.bind(this)
    this.toggleVisibility = this.toggleVisibility.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
    this._updateFidelitySettings = this._updateFidelitySettings.bind(this)
    this.dispose = this.dispose.bind(this)
    
    // Initialize disposable resource tracking
    this.disposableResource = new DisposableResource()
  }

  init (bundle) {
    this.bundle = bundle
    this.globalConfig = this.bundle.globalConfig
  }

  // Load the board
  init3d (threejsNode) {
    this.threejsNode = threejsNode
    this.fidelity = 0
    this.usePipeline = false
    this.isVisible = true
    this.isScreenshotMode = false

    this._initMaterials()
    this._initbaseplateBox()
    this._initStudGeometries()

    // create scene for pipeline
    return this.pipelineScene = this.bundle.renderer.getDefaultScene()
  }

  _initbaseplateBox () {
    // Create baseplate with 5 faces in each direction
    const box = this.disposableResource.track(new THREE.BoxGeometry(dimension, dimension, 8, 5, 5))
    const bufferGeometry = this.disposableResource.track(new THREE.BufferGeometry())
    bufferGeometry.fromGeometry(box)
    this.baseplateBox = this.disposableResource.track(new THREE.Mesh(bufferGeometry, this.baseplateMaterial))
    this.baseplateBox.translateZ(-4)
    return this.threejsNode.add(this.baseplateBox)
  }

  _initStudGeometries () {
    this.studsContainer = this.disposableResource.track(this._generateStuds(7))
    this.studsContainer.visible = false
    this.threejsNode.add(this.studsContainer)

    this.highFiStudsContainer = this.disposableResource.track(this._generateStuds(42))
    this.highFiStudsContainer.visible = false
    return this.threejsNode.add(this.highFiStudsContainer)
  }

  _generateStuds (radiusSegments) {
    let x; let y
    let asc; let end; let step
    let asc2; let end2; let step2
    const studGeometry = new THREE.CylinderGeometry(
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.radius,
      this.globalConfig.studSize.height,
      radiusSegments,
    )
    const rotation = new THREE.Matrix4()
    rotation.makeRotationX(1.571)
    studGeometry.applyMatrix(rotation)

    const translation = new THREE.Matrix4()
    translation.makeTranslation(0, 0, this.globalConfig.studSize.height / 2)
    studGeometry.applyMatrix(translation)

    const studsGeometry = new THREE.Geometry()
    const xSpacing = this.globalConfig.gridSpacing.x
    const ySpacing = this.globalConfig.gridSpacing.y
    const studsGeometrySize = 80
    for (x = 0, end = studsGeometrySize, step = xSpacing, asc = step > 0; asc ? x < end : x > end; x += step) {
      var asc1; var end1; var step1
      for (y = 0, end1 = studsGeometrySize, step1 = ySpacing, asc1 = step1 > 0; asc1 ? y < end1 : y > end1; y += step1) {
        translation.makeTranslation(x, y, 0)
        studsGeometry.merge(studGeometry, translation)
      }
    }
    
    // Dispose the original study geometry since it's been merged
    studGeometry.dispose()
    
    const bufferGeometry = new THREE.BufferGeometry()
    bufferGeometry.fromGeometry(studsGeometry)
    
    // Dispose the original geometry after conversion
    studsGeometry.dispose()

    const container = new THREE.Object3D()
    for (x = (-dimension + xSpacing) / 2, end2 = dimension / 2, step2 = studsGeometrySize, asc2 = step2 > 0; asc2 ? x < end2 : x > end2; x += step2) {
      var asc3; var end3; var step3
      for (y = (-dimension + ySpacing) / 2, end3 = dimension / 2, step3 = studsGeometrySize, asc3 = step3 > 0; asc3 ? y < end3 : y > end3; y += step3) {
        // Track the buffer geometry and mesh
        const mesh = new THREE.Mesh(bufferGeometry, this.studMaterial)
        mesh.translateX(x)
        mesh.translateY(y)
        container.add(mesh)
      }
    }
    
    // Track the buffer geometry for disposal
    this.disposableResource.track(bufferGeometry)

    return container
  }

  _initMaterials () {
    const studTexture = this.disposableResource.track(THREE.ImageUtils.loadTexture("/img/baseplateStud.png"))
    studTexture.wrapS = THREE.RepeatWrapping
    studTexture.wrapT = THREE.RepeatWrapping
    studTexture.repeat.set(dimension / 8, dimension / 8)

    this.baseplateMaterial = this.disposableResource.track(new THREE.MeshLambertMaterial({
      color: this.globalConfig.colors.basePlate,
    }))
    this.baseplateTexturedMaterial = this.disposableResource.track(new THREE.MeshLambertMaterial({
      map: studTexture,
    }))
    this.currentBaseplateMaterial = this.baseplateTexturedMaterial

    this.baseplateTransparentMaterial = this.disposableResource.track(new THREE.MeshLambertMaterial({
      color: this.globalConfig.colors.basePlate,
      opacity: 0.4,
      transparent: true,
    }))

    return this.studMaterial = this.disposableResource.track(new THREE.MeshLambertMaterial({
      color: this.globalConfig.colors.basePlateStud,
    }))
  }

  on3dUpdate () {
    // This check is only important if we don't use the pipeline
    if (this.usePipeline || this.isScreenshotMode) {
      return
    }

    // Check if the camera is below z=0. if yes, make the plate transparent
    // and hide studs
    if (this.bundle == null) {
      return
    }

    const {
      camera,
    } = this.bundle.renderer

    if (camera.position.z < 0) {
      this.baseplateBox.material = this.baseplateTransparentMaterial
      this.studsContainer.visible = false
      return this.highFiStudsContainer.visible = false
    }
    else {
      return this._updateFidelitySettings()
    }
  }

  onPaint (threeRenderer, camera, target) {
    if (!this.isVisible || this.isScreenshotMode) {
      return
    }

    // Recreate textures if either they havent been generated yet or
    // the screen size has changed
    if (!((this.renderTargetsInitialized != null) &&
    RenderTargetHelper.renderTargetHasRightSize(
      this.pipelineSceneTarget.renderTarget, threeRenderer,
    ))) {
      if (this.pipelineSceneTarget != null) {
        RenderTargetHelper.deleteRenderTarget(this.pipelineSceneTarget, threeRenderer)
        this.disposableResource.untrack(this.pipelineSceneTarget)
      }

      this.pipelineSceneTarget = this.disposableResource.track(RenderTargetHelper.createRenderTarget(
        threeRenderer, null, null, 1.0,
      ))
      this.renderTargetsInitialized = true
    }

    // Render board
    threeRenderer.render(
      this.pipelineScene, camera, this.pipelineSceneTarget.renderTarget, true,
    )

    const gl = threeRenderer.context

    // Render baseplate transparent if cam looks from below
    if (camera.position.z < 0) {
      // One fully transparent render pass
      this.pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4
      return threeRenderer.render(this.pipelineSceneTarget.quadScene, camera, target, false)
    }
    else {
      // One default opaque pass
      this.pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 1
      threeRenderer.render(this.pipelineSceneTarget.quadScene, camera, target, false)

      // Render one pass transparent, where visible object or shadow is
      // (= no lego)
      gl.enable(gl.STENCIL_TEST)
      gl.stencilFunc(gl.EQUAL, 0x00, stencilBits.legoMask)
      gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)
      gl.stencilMask(0x00)

      this.pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4

      gl.disable(gl.DEPTH_TEST)
      threeRenderer.render(this.pipelineSceneTarget.quadScene, camera, target, false)
      gl.enable(gl.DEPTH_TEST)

      return gl.disable(gl.STENCIL_TEST)
    }
  }

  toggleVisibility () {
    this.threejsNode.visible = !this.threejsNode.visible
    return this.isVisible = !this.isVisible
  }

  setFidelity (fidelityLevel, availableLevels, options) {
    if (options.screenshotMode != null) {
      this.isScreenshotMode = options.screenshotMode
      this.threejsNode.visible = this.isVisible && !this.isScreenshotMode
    }

    // Determine whether to show or hide studs
    if (fidelityLevel >= availableLevels.indexOf("PipelineHigh")) {
      this.fidelity = 2
      this._updateFidelitySettings()
    }
    else if (fidelityLevel > availableLevels.indexOf("DefaultMedium")) {
      this.fidelity = 1
      this._updateFidelitySettings()
    }
    else {
      this.fidelity = 0
      this._updateFidelitySettings()
    }

    // Determine whether to use the pipeline or not
    if (fidelityLevel >= availableLevels.indexOf("PipelineLow")) {
      if (!this.usePipeline) {
        this.usePipeline = true

        // move lego board and studs from threeNode to pipeline scene
        return this._moveThreeObjects(this.threejsNode, this.pipelineScene, [
          this.baseplateBox,
          this.studsContainer,
          this.highFiStudsContainer,
        ])
      }
    }
    else {
      if (this.usePipeline) {
        this.usePipeline = false

        // move lego board and studs from pipeline to threeNode
        return this._moveThreeObjects(this.pipelineScene, this.threejsNode, [
          this.baseplateBox,
          this.studsContainer,
          this.highFiStudsContainer,
        ])
      }
    }
  }

  _moveThreeObjects (from, to, objects) {
    return (() => {
      const result = []
      for (const object of Array.from(objects)) {
        from.remove(object)
        result.push(to.add(object))
      }
      return result
    })()
  }

  _updateFidelitySettings () {
    // show studs?
    this.studsContainer.visible = this.fidelity === 1
    this.highFiStudsContainer.visible = this.fidelity === 2

    // remove texture because we have physical studs?
    if (this.fidelity === 0) {
      this.baseplateBox.material =  this.baseplateTexturedMaterial
    }
    else {
      this.baseplateBox.material = this.baseplateMaterial
    }
    return this.currentBaseplateMaterial = this.baseplateBox.material
  }

  dispose() {
    if (this.disposableResource && !this.disposableResource.isDisposed()) {
      // Clean up render targets
      if (this.pipelineSceneTarget) {
        RenderTargetHelper.deleteRenderTarget(this.pipelineSceneTarget, this.bundle?.renderer?.threeRenderer)
      }
      
      // Remove objects from scenes
      if (this.threejsNode) {
        if (this.baseplateBox) this.threejsNode.remove(this.baseplateBox)
        if (this.studsContainer) this.threejsNode.remove(this.studsContainer)
        if (this.highFiStudsContainer) this.threejsNode.remove(this.highFiStudsContainer)
      }
      
      if (this.pipelineScene) {
        if (this.baseplateBox) this.pipelineScene.remove(this.baseplateBox)
        if (this.studsContainer) this.pipelineScene.remove(this.studsContainer)
        if (this.highFiStudsContainer) this.pipelineScene.remove(this.highFiStudsContainer)
      }
      
      // Dispose all tracked resources
      this.disposableResource.dispose()
      this.disposableResource = null
      
      // Clear references
      this.bundle = null
      this.globalConfig = null
      this.threejsNode = null
      this.pipelineScene = null
      this.baseplateBox = null
      this.studsContainer = null
      this.highFiStudsContainer = null
      this.pipelineSceneTarget = null
      this.baseplateMaterial = null
      this.baseplateTexturedMaterial = null
      this.baseplateTransparentMaterial = null
      this.studMaterial = null
      this.currentBaseplateMaterial = null
    }
  }
}
