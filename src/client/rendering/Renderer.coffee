THREE = require 'three'
OrbitControls = require('three-orbit-controls')(THREE)
renderTargetHelper = require './renderTargetHelper'
FxaaShaderPart = require './shader/FxaaPart'
SsaoShaderPart = require './shader/ssaoPart'
SsaoBlurPart = require './shader/ssaoBlurPart'
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
		@usePipelineSsao = false
		@imageRenderQueries = []

	# renders the current scene to an image, uses the camera if provided
	# returns a promise which will resolve with the image
	renderToImage: (camera = @camera, resolution = null) =>
		return new Promise (resolve, reject) =>
			@imageRenderQueries.push {
				resolve
				reject
				camera
				resolution: renderTargetHelper.getNextValidTextureDimension resolution
			}

	localRenderer: (timestamp) =>
		if @imageRenderQueries.length == 0
			@_renderFrame timestamp, @camera, null
		else
			@_renderImage timestamp

		# call update hook
		@pluginHooks.on3dUpdate timestamp
		@controls?.update()
		@animationRequestID = requestAnimationFrame @localRenderer

	# Renders all plugins
	_renderFrame: (timestamp, camera, renderTarget = null) =>
		# Clear screen
		@threeRenderer.setRenderTarget(renderTarget)
		@threeRenderer.context.stencilMask(0xFF)
		@threeRenderer.clear()

		# Render the default scene (plugins add objects in the init3d hook)
		@threeRenderer.render @scene, camera, renderTarget

		# Allow for custom render passes
		if @pipelineEnabled
			# Init render target
			@_initializePipelineTarget()

			# Clear render target
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

			# Render our target to the screen
			@threeRenderer.render @pipelineRenderTarget.quadScene, @camera

			if @usePipelineSsao
				# Take data from our target and render SSAO
				# data into gauss target
				@threeRenderer.render(
					@ssaoTarget.quadScene, @camera, @ssaoBlurTarget.renderTarget, true
				)

				# Take the ssao values and render a gaussed version on the screen
				@threeRenderer.render(
					@ssaoBlurTarget.quadScene, @camera
				)

	_renderImage: (timestamp) =>
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

	# Create / update target for all pipeline passes
	_initializePipelineTarget: =>
		if not @pipelineRenderTarget? or @pipelineRenderTarget.dirty or
		not renderTargetHelper.renderTargetHasRightSize(
			@pipelineRenderTarget.renderTarget, @threeRenderer
		)
			# Create the render target that renders everything antialiased to the screen
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

			if @usePipelineSsao
				# Get a random texture for SSAO
				randomTex = THREE.ImageUtils.loadTexture('img/randomTexture.png')
				randomTex.wrapS = THREE.RepeatWrapping
				randomTex.wrapT = THREE.RepeatWrapping

				# Delete existing Targets
				if @ssaoTarget?
					renderTargetHelper.deleteRenderTarget @ssaoTarget, @threeRenderer
				if @ssaoBlurTarget?
					renderTargetHelper.deleteRenderTarget @ssaoBlurTarget, @threeRenderer

				# Clone the pipeline Rendertarget:
				# use this render target to create SSAO values out of scene
				@ssaoTarget = renderTargetHelper.cloneRenderTarget(
					@pipelineRenderTarget,
					[new SsaoShaderPart()],
					{tRandom: {	type: 't', value: randomTex}},
					1.0
				)

				# Create a rendertarget that applies a gauss filter on everything
				@ssaoBlurTarget = renderTargetHelper.createRenderTarget(
					@threeRenderer,
					[new SsaoBlurPart()],
					{},
					1.0,
					@useBigPipelineTargets
				)

	setFidelity: (fidelityLevel, availableLevels) =>
		@pipelineEnabled = fidelityLevel >= availableLevels.indexOf 'PipelineLow'

		if @pipelineEnabled
			# Determine whether to use FXAA
			if fidelityLevel >= availableLevels.indexOf 'PipelineMedium'
				# Only do something when FXAA is not already used
				if not @usePipelineFxaa
					@usePipelineFxaa = true
					@pipelineRenderTarget = null
			else
				if @usePipelineFxaa
					@usePipelineFxaa = false
					@pipelineRenderTarget = null

			# Determine whether to use bigger render targets (super sampling)
			if fidelityLevel >= availableLevels.indexOf 'PipelineHigh'
				@useBigRendertargets = true
			else
				@useBigRendertargets = false

			renderTargetHelper.configureSize @useBigRendertargets

			# Determine wether to use SSAO
			if fidelityLevel >= availableLevels.indexOf 'PipelineUltra'
				# Only do something when SSAO is not already used
				if not @usePipelineSsao
					@usePipelineSsao = true

					if @pipelineRenderTarget?
						@pipelineRenderTarget.dirty = true
			else
				if @usePipelineSsao
					@usePipelineSsao = false

					if @pipelineRenderTarget?
						@pipelineRenderTarget.dirty = true

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
		# Zooms out/in the camera so that the object is fully visible
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
			logarithmicDepthBuffer: false
			canvas: document.getElementById globalConfig.renderAreaId
		)
		@threeRenderer.sortObjects = false

		# Needed for rendering pipeline
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

	# Creates a scene with default light and rotation settings
	getDefaultScene: =>
		scene = @_setupScene(@globalConfig)
		@_setupLighting(scene)
		return scene

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
