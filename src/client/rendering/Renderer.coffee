THREE = require 'three'
OrbitControls = require('three-orbit-controls')(THREE)
renderTargetHelper = require './renderTargetHelper'
FxaaShaderPart = require './shader/FxaaPart'
log = require 'loglevel'
threeHelper = require '../threeHelper'

###
# @class Renderer
###
class Renderer
	constructor: (@pluginHooks, globalConfig) ->
		@scene = null
		@camera = null
		@threeRenderer = null
		@init globalConfig
		@pipelineEnabled = false
		@useBigRendertargets = false
		@imageRenderQueries = []

	# renders the current scene to an image, uses the camera if provided
	# returns a promise which will resolve with the image
	renderToImage: (camera = @camera, resolution = null) =>
		return new Promise (resolve, reject) =>
			@imageRenderQueries.push {
				resolve: resolve
				reject: reject
				camera: camera
				resolution: renderTargetHelper.getNextValidTextureDimension resolution
			}

	localRenderer: (timestamp) =>
		if @imageRenderQueries.length == 0
			@_renderFrame timestamp, @camera, null
		else
			# render first query to image
			imageQuery = @imageRenderQueries.shift()

			# override render size if requested
			if imageQuery.resolution?
				renderTargetHelper.configureSize true, imageQuery.resolution

			# create rendertarget
			if not @imageRenderTarget? or
			not renderTargetHelper.renderTargetHasRightSize(
				@imageRenderTarget.renderTarget, @threeRenderer
			)
				if @imageRenderTarget?
					renderTargetHelper.deleteRenderTarget @imageRenderTarget, @threeRenderer

				@imageRenderTarget = renderTargetHelper.createRenderTarget(
					@threeRenderer,
					[],
					null,
					1.0
				)

			# render to target
			@_renderFrame timestamp, imageQuery.camera, @imageRenderTarget.renderTarget

			# save image data
			width = @imageRenderTarget.renderTarget.width
			height = @imageRenderTarget.renderTarget.height

			pixels = new Uint8Array(width * height * 4)

			# fix three inconsistency on current depthTarget dev branch
			rt = @imageRenderTarget.renderTarget
			rt.format = rt.texture.format

			@threeRenderer.readRenderTargetPixels(
				@imageRenderTarget.renderTarget, 0, 0,
				width, height, pixels
			)

			# restore original renderTarget size if it was altered
			if imageQuery.resolution?
				renderTargetHelper.configureSize @useBigRendertargets

			# resolve promise
			imageQuery.resolve {
				viewWidth: @size().width
				viewHeight: @size().height
				imageWidth: width
				imageHeight: height
				pixels: pixels
			}

		# call update hook
		@pluginHooks.on3dUpdate timestamp
		@controls?.update()
		@animationRequestID = requestAnimationFrame @localRenderer

	# Renders all plugins
	_renderFrame: (timestamp, camera, renderTarget = null) =>
		# clear screen
		@threeRenderer.setRenderTarget(renderTarget)
		@threeRenderer.context.stencilMask(0xFF)
		@threeRenderer.clear()

		# render the default scene (plugins add objects in the init3d hook)
		@threeRenderer.render @scene, camera, renderTarget

		# allow for custom render passes
		if @pipelineEnabled
			# init render target
			@_initializePipelineTarget()

			# clear render target
			@threeRenderer.setRenderTarget(@pipelineRenderTarget.renderTarget)
			@threeRenderer.context.stencilMask(0xFF)
			@threeRenderer.clear()
			@threeRenderer.setRenderTarget(null)

			# let plugins render in our target
			@pluginHooks.onPaint(
				@threeRenderer,
				camera,
				@pipelineRenderTarget.renderTarget
			)

			# render our target to the screen
			@threeRenderer.render @pipelineRenderTarget.quadScene, camera, renderTarget

	# create / update target for all pipeline passes
	_initializePipelineTarget: =>
		if not @pipelineRenderTarget? or
		not renderTargetHelper.renderTargetHasRightSize(
			@pipelineRenderTarget.renderTarget, @threeRenderer
		)
			shaderParts = []
			if @usePipelineFxaa
				shaderParts.push new FxaaShaderPart()

			if @pipelineRenderTarget?
				renderTargetHelper.deleteRenderTarget @pipelineRenderTarget, @threeRenderer

			@pipelineRenderTarget = renderTargetHelper.createRenderTarget(
				@threeRenderer,
				shaderParts,
				null,
				1.0
			)

	setFidelity: (fidelityLevel, availableLevels) =>
		if @pipelineEnabled
			# Determine whether to use bigger render targets (super sampling)
			if fidelityLevel >= availableLevels.indexOf 'PipelineHigh'
				@useBigRendertargets = true
			else
				@useBigRendertargets = false

			renderTargetHelper.configureSize @useBigRendertargets

			# determine whether to use FXAA
			if fidelityLevel >= availableLevels.indexOf 'PipelineMedium'
				if not @usePipelineFxaa
					@usePipelineFxaa = true
					@pipelineRenderTarget = null
			else
				if @usePipelineFxaa
					@usePipelineFxaa = false
					@pipelineRenderTarget = null

	addToScene: (node) ->
		@scene.add node

	getDomElement: ->
		return @threeRenderer.domElement

	getCamera: ->
		return @camera

	windowResizeHandler: ->
		if not @staticRendererSize
			@camera.aspect = @size().width / @size().height
			@camera.updateProjectionMatrix()
			@threeRenderer.setSize @size().width, @size().height

		@threeRenderer.render @scene, @camera

	zoomToNode: (threeNode) ->
		boundingSphere = threeHelper.getBoundingSphere threeNode
		# zooms out/in the camera so that the object is fully visible
		threeHelper.zoomToBoundingSphere @camera, @scene, @controls, boundingSphere

	init: (@globalConfig) ->
		@_setupSize @globalConfig
		@_setupRenderer @globalConfig
		@scene = @getDefaultScene()
		@_setupCamera @globalConfig
		@animationRequestID = requestAnimationFrame @localRenderer

	_setupSize: (globalConfig) ->
		if not globalConfig.staticRendererSize
			@staticRendererSize = false
		else
			@staticRendererSize = true
			@staticRendererWidth = globalConfig.staticRendererWidth
			@staticRendererHeight = globalConfig.staticRendererHeight

	size: ->
		if @staticRendererSize
			return {width: @staticRendererWidth, height: @staticRendererHeight}
		else
			return {width: window.innerWidth, height: window.innerHeight}

	_setupRenderer: (globalConfig) ->
		@threeRenderer = new THREE.WebGLRenderer(
			alpha: true
			antialias: true
			stencil: true
			preserveDrawingBuffer: true
			canvas: document.getElementById globalConfig.renderAreaId
		)
		@threeRenderer.sortObjects = false

		# needed for rendering pipeline
		@threeRenderer.extensions.get 'EXT_frag_depth'

		# Stencil test
		gl = @threeRenderer.context
		contextAttributes = gl.getContextAttributes()
		if not contextAttributes.stencil
			log.warn 'The current WebGL context does not have a stencil buffer.
			 Rendering will be (partly) broken'
			@threeRenderer.hasStencilBuffer = false
		else
			@threeRenderer.hasStencilBuffer = true

		@threeRenderer.setSize @size().width, @size().height
		@threeRenderer.autoClear = false

	_setupScene: (globalConfig) ->
		scene = new THREE.Scene()
		scene.fog = new THREE.Fog(
			globalConfig.colors.background
			globalConfig.cameraNearPlane
			globalConfig.cameraFarPlane
		)

		return scene

	_setupCamera: (globalConfig) ->
		@camera = new THREE.PerspectiveCamera(
			globalConfig.fov,
			(@size().width / @size().height),
			globalConfig.cameraNearPlane,
			globalConfig.cameraFarPlane
		)
		@camera.position.set(
			globalConfig.axisLength
			globalConfig.axisLength
			globalConfig.axisLength
		)
		@camera.up.set(0, 0, 1)
		@camera.lookAt(new THREE.Vector3(0, 0, 0))

	setupControls: (globalConfig, controls) ->
		if controls?
			controls.addObject @camera
			controls.addDomElement @threeRenderer.domElement
			controls.update()
			@controls = controls
		else
			@controls = new OrbitControls(@camera, @threeRenderer.domElement)
			for key, value of globalConfig.orbitControls
				@controls[key] = value
			@controls.target.set(0, 0, 0)

	_setupLighting: (scene) ->
		ambientLight = new THREE.AmbientLight(0x404040)
		scene.add ambientLight

		directionalLight = new THREE.DirectionalLight(0xffffff)
		directionalLight.position.set 0, 20, 30
		scene.add directionalLight

		directionalLight = new THREE.DirectionalLight(0x808080)
		directionalLight.position.set 20, 0, 30
		scene.add directionalLight

		directionalLight = new THREE.DirectionalLight(0x808080)
		directionalLight.position.set 20, -20, -30
		scene.add directionalLight

	# creates a scene with default light and rotation settings
	getDefaultScene: =>
		scene = @_setupScene(@globalConfig)
		@_setupLighting(scene)
		return scene

	loadCamera: (state) =>
		if state.controls?
			@setCamera state.controls.position, state.controls.target

	saveCamera: (state) =>
		p = @camera.position
		t = @controls.target
		state.controls = {
			position: { x: p.x, y: p.y, z: p.z }
			target: { x: t.x, y: t.y, z: t.z }
		}

	getControls: =>
		@controls

	toggleRendering: =>
		if @animationRequestID?
			cancelAnimationFrame @animationRequestID
			@animationRequestID = null
			@controls.enabled = false
		else
			@animationRequestID = requestAnimationFrame @localRenderer
			@controls.enabled = true


module.exports = Renderer
