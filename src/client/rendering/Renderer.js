import extend from "extend"
import THREE from "three"
import PointerControls from "three-pointer-controls"
import log from "loglevel"

import renderTargetHelper from "./renderTargetHelper.js"
import FxaaShaderPart from "./shader/FxaaPart.js"
import SsaoShaderPart from "./shader/ssaoPart.js"
import SsaoBlurPart from "./shader/ssaoBlurPart.js"
import threeHelper from "../threeHelper.js"

/*
 * @class Renderer
 */
export default class Renderer {
  constructor (pluginHooks, globalConfig, controls) {
    this.renderToImage = this.renderToImage.bind(this)
    this.localRenderer = this.localRenderer.bind(this)
    this._renderFrame = this._renderFrame.bind(this)
    this._renderImage = this._renderImage.bind(this)
    this._initializePipelineTarget = this._initializePipelineTarget.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
    this.getControls = this.getControls.bind(this)
    this.getDefaultScene = this.getDefaultScene.bind(this)
    this.toggleRendering = this.toggleRendering.bind(this)
    this.pluginHooks = pluginHooks
    this.scene = null
    this.camera = null
    this.threeRenderer = null
    this.init(globalConfig, controls)
    this.pipelineEnabled = false
    this.useBigRendertargets = false
    this.usePipelineSsao = false
    this.imageRenderQueries = []
  }

  // renders the current scene to an image, uses the camera if provided
  // returns a promise which will resolve with the image
  renderToImage (camera, resolution = null) {
    if (camera == null) {
      ({
        camera,
      } = this)
    }
    return new Promise((resolve, reject) => {
      return this.imageRenderQueries.push({
        resolve,
        reject,
        camera,
        resolution: renderTargetHelper.getNextValidTextureDimension(resolution),
      })
    })
  }

  localRenderer (timestamp) {
    this._updateSize()

    if (this.imageRenderQueries.length === 0) {
      this._renderFrame(timestamp, this.camera, null)
    }
    else {
      this._renderImage(timestamp)
    }

    // call update hook
    this.pluginHooks.on3dUpdate(timestamp)
    return this.animationRequestID = requestAnimationFrame(this.localRenderer)
  }

  // Renders all plugins
  _renderFrame (timestamp, camera, renderTarget = null) {
    // Clear screen
    this.threeRenderer.setRenderTarget(renderTarget)
    this.threeRenderer.context.stencilMask(0xFF)
    this.threeRenderer.clear()

    // Render the default scene (plugins add objects in the init3d hook)
    this.threeRenderer.render(this.scene, camera, renderTarget)

    // Allow for custom render passes
    if (this.pipelineEnabled) {
      // Init render target
      this._initializePipelineTarget()

      // Clear render target
      this.threeRenderer.setRenderTarget(this.pipelineRenderTarget.renderTarget)
      this.threeRenderer.context.stencilMask(0xFF)
      this.threeRenderer.clear()
      this.threeRenderer.setRenderTarget(null)

      // let plugins render in our target
      this.pluginHooks.onPaint(
        this.threeRenderer,
        camera,
        this.pipelineRenderTarget.renderTarget,
      )

      // Render our target to the screen
      this.threeRenderer.render(this.pipelineRenderTarget.quadScene, this.camera)

      if (this.usePipelineSsao) {
        // Take data from our target and render SSAO
        // data into gauss target
        this.threeRenderer.render(
          this.ssaoTarget.quadScene, this.camera, this.ssaoBlurTarget.renderTarget, true,
        )

        // Take the SSAO values and render a gaussed version on the screen
        return this.threeRenderer.render(
          this.ssaoBlurTarget.quadScene, this.camera,
        )
      }
    }
  }

  _renderImage (timestamp) {
    // render first query to image
    const imageQuery = this.imageRenderQueries.shift()

    // override render size if requested
    if (imageQuery.resolution != null) {
      renderTargetHelper.configureSize(true, imageQuery.resolution)
    }

    // create rendertarget
    if ((this.imageRenderTarget == null) ||
      !renderTargetHelper.renderTargetHasRightSize(
        this.imageRenderTarget.renderTarget, this.threeRenderer,
      )) {
      if (this.imageRenderTarget != null) {
        renderTargetHelper.deleteRenderTarget(this.imageRenderTarget, this.threeRenderer)
      }

      this.imageRenderTarget = renderTargetHelper.createRenderTarget(
        this.threeRenderer,
        [],
        null,
        1.0,
      )
    }

    // render to target
    this._renderFrame(timestamp, imageQuery.camera, this.imageRenderTarget.renderTarget)

    // save image data
    const {
      width,
    } = this.imageRenderTarget.renderTarget
    const {
      height,
    } = this.imageRenderTarget.renderTarget

    const pixels = new Uint8Array(width * height * 4)

    // fix three inconsistency on current depthTarget dev branch
    const rt = this.imageRenderTarget.renderTarget
    rt.format = rt.texture.format

    this.threeRenderer.readRenderTargetPixels(
      this.imageRenderTarget.renderTarget, 0, 0,
      width, height, pixels,
    )

    // restore original renderTarget size if it was altered
    if (imageQuery.resolution != null) {
      renderTargetHelper.configureSize(this.useBigRendertargets)
    }

    // resolve promise
    return imageQuery.resolve({
      viewWidth: this.size().width,
      viewHeight: this.size().height,
      imageWidth: width,
      imageHeight: height,
      pixels,
    })
  }

  // Create / update target for all pipeline passes
  _initializePipelineTarget () {
    if ((this.pipelineRenderTarget == null) || this.pipelineRenderTarget.dirty ||
    !renderTargetHelper.renderTargetHasRightSize(
      this.pipelineRenderTarget.renderTarget, this.threeRenderer,
    )) {
      // Create the render target that renders everything anti-aliased to the screen
      const shaderParts = []
      if (this.usePipelineFxaa) {
        shaderParts.push(new FxaaShaderPart())
      }

      if (this.pipelineRenderTarget != null) {
        renderTargetHelper.deleteRenderTarget(this.pipelineRenderTarget, this.threeRenderer)
      }

      this.pipelineRenderTarget = renderTargetHelper.createRenderTarget(
        this.threeRenderer,
        shaderParts,
        null,
        1.0,
      )

      if (this.usePipelineSsao) {
        // Get a random texture for SSAO
        const randomTex = THREE.ImageUtils.loadTexture("img/randomTexture.png")
        randomTex.wrapS = THREE.RepeatWrapping
        randomTex.wrapT = THREE.RepeatWrapping

        // Delete existing Targets
        if (this.ssaoTarget != null) {
          renderTargetHelper.deleteRenderTarget(this.ssaoTarget, this.threeRenderer)
        }
        if (this.ssaoBlurTarget != null) {
          renderTargetHelper.deleteRenderTarget(this.ssaoBlurTarget, this.threeRenderer)
        }

        // Clone the pipeline render target:
        // use this render target to create SSAO values out of scene
        this.ssaoTarget = renderTargetHelper.cloneRenderTarget(
          this.pipelineRenderTarget,
          [new SsaoShaderPart()],
          {tRandom: { type: "t", value: randomTex}},
          1.0,
        )

        // Create a rendertarget that applies a gauss filter on everything
        return this.ssaoBlurTarget = renderTargetHelper.createRenderTarget(
          this.threeRenderer,
          [new SsaoBlurPart()],
          {},
          1.0,
          this.useBigPipelineTargets,
        )
      }
    }
  }

  setFidelity (fidelityLevel, availableLevels) {
    this.pipelineEnabled = fidelityLevel >= availableLevels.indexOf("PipelineLow")

    if (this.pipelineEnabled) {
      // Determine whether to use FXAA
      if (fidelityLevel >= availableLevels.indexOf("PipelineMedium")) {
        // Only do something when FXAA is not already used
        if (!this.usePipelineFxaa) {
          this.usePipelineFxaa = true
          this.pipelineRenderTarget = null
        }
      }
      else {
        if (this.usePipelineFxaa) {
          this.usePipelineFxaa = false
          this.pipelineRenderTarget = null
        }
      }

      // Determine whether to use bigger render targets (super sampling)
      this.useBigRendertargets =
        fidelityLevel >= availableLevels.indexOf("PipelineHigh")

      renderTargetHelper.configureSize(this.useBigRendertargets)

      // Determine whether to use SSAO
      if (fidelityLevel >= availableLevels.indexOf("PipelineUltra")) {
        // Only do something when SSAO is not already used
        if (!this.usePipelineSsao) {
          this.usePipelineSsao = true

          return this.pipelineRenderTarget != null ? this.pipelineRenderTarget.dirty = true : undefined
        }
      }
      else {
        if (this.usePipelineSsao) {
          this.usePipelineSsao = false

          return this.pipelineRenderTarget != null ? this.pipelineRenderTarget.dirty = true : undefined
        }
      }
    }
  }

  addToScene (node) {
    return this.scene.add(node)
  }

  getDomElement () {
    return this.threeRenderer.domElement
  }

  getCamera () {
    return this.camera
  }

  windowResizeHandler () {
    if (!this.staticRendererSize) {
      this.camera.aspect = this.size().width / this.size().height
      this.camera.updateProjectionMatrix()
      this._updateSize(true)
    }

    return this.threeRenderer.render(this.scene, this.camera)
  }

  zoomToNode (threeNode) {
    const boundingSphere = threeHelper.getBoundingSphere(threeNode)
    // Zooms out/in the camera so that the object is fully visible
    return threeHelper.zoomToBoundingSphere(this.camera, this.scene, this.controls, boundingSphere)
  }

  init (globalConfig, controls) {
    this.globalConfig = globalConfig
    this._setupSize(this.globalConfig)
    this._setupRenderer(this.globalConfig)
    this.scene = this.getDefaultScene()
    this._setupCamera(this.globalConfig)
    this._setupControls(this.globalConfig, controls)

    return this.animationRequestID = requestAnimationFrame(this.localRenderer)
  }

  _setupSize (globalConfig) {
    if (!globalConfig.staticRendererSize) {
      return this.staticRendererSize = false
    }
    else {
      this.staticRendererSize = true
      this.staticRendererWidth = globalConfig.staticRendererWidth
      return this.staticRendererHeight = globalConfig.staticRendererHeight
    }
  }

  size () {
    if (this.staticRendererSize) {
      return {width: this.staticRendererWidth, height: this.staticRendererHeight}
    }
    else {
      return {width: window.innerWidth, height: window.innerHeight}
    }
  }

  _setupRenderer (globalConfig) {
    this.threeRenderer = new THREE.WebGLRenderer({
      alpha: true,
      antialias: true,
      stencil: true,
      preserveDrawingBuffer: true,
      logarithmicDepthBuffer: false,
      canvas: document.getElementById(globalConfig.renderAreaId),
    })
    this.threeRenderer.sortObjects = false

    // Needed for rendering pipeline
    this.threeRenderer.extensions.get("EXT_frag_depth")

    // Stencil test
    const gl = this.threeRenderer.context
    const contextAttributes = gl.getContextAttributes()
    if (!contextAttributes.stencil) {
      log.warn("The current WebGL context does not have a stencil buffer. \
Rendering will be (partly) broken",
      )
      this.threeRenderer.hasStencilBuffer = false
    }
    else {
      this.threeRenderer.hasStencilBuffer = true
    }

    return this.threeRenderer.autoClear = false
  }

  _updateSize (forceUpdate) {
    const devicePixelRatio = window.devicePixelRatio || 1
    if (forceUpdate || (devicePixelRatio !== this.devicePixelRatio)) {
      this.devicePixelRatio = devicePixelRatio
      this.threeRenderer.setPixelRatio(devicePixelRatio)
      return this.threeRenderer.setSize(this.size().width, this.size().height)
    }
  }

  _setupScene (globalConfig) {
    const scene = new THREE.Scene()

    scene.fog = new THREE.Fog(
      globalConfig.colors.background,
      globalConfig.cameraNearPlane,
      globalConfig.cameraFarPlane,
    )

    return scene
  }

  _setupCamera (globalConfig) {
    this.camera = new THREE.PerspectiveCamera(
      globalConfig.fov,
      this.size().width / this.size().height,
      globalConfig.cameraNearPlane,
      globalConfig.cameraFarPlane,
    )
    this.camera.position.set(
      globalConfig.axisLength,
      globalConfig.axisLength,
      globalConfig.axisLength,
    )
    this.camera.up.set(0, 0, 1)
    return this.camera.lookAt(new THREE.Vector3(0, 0, 0))
  }

  _setupControls (globalConfig, controls) {
    if (!controls) {
      controls = new PointerControls()
      extend(true, controls.config, globalConfig.controls)
    }
    return this.controls = controls
  }

  initControls () {
    return this.controls.control(this.camera)
      .with(this.threeRenderer.domElement)
  }

  getControls () {
    return this.controls
  }

  _setupLighting (scene) {
    const ambientLight = new THREE.AmbientLight(0x404040)
    scene.add(ambientLight)

    let directionalLight = new THREE.DirectionalLight(0xffffff)
    directionalLight.position.set(0, 20, 30)
    scene.add(directionalLight)

    directionalLight = new THREE.DirectionalLight(0x808080)
    directionalLight.position.set(20, 0, 30)
    scene.add(directionalLight)

    directionalLight = new THREE.DirectionalLight(0x808080)
    directionalLight.position.set(20, -20, -30)
    return scene.add(directionalLight)
  }

  // Creates a scene with default light and rotation settings
  getDefaultScene () {
    const scene = this._setupScene(this.globalConfig)
    this._setupLighting(scene)
    return scene
  }

  toggleRendering () {
    if (this.animationRequestID != null) {
      cancelAnimationFrame(this.animationRequestID)
      this.animationRequestID = null
      return this.controls.config.enabled = false
    }
    else {
      this.animationRequestID = requestAnimationFrame(this.localRenderer)
      return this.controls.config.enabled = true
    }
  }
}
