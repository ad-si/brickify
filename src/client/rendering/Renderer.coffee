THREE = require 'three'
OrbitControls = require('three-orbit-controls')(THREE)
renderTargetHelper = require './renderTargetHelper'
FxaaShaderPart = require './shader/FxaaPart'
SsaoShaderPart = require './shader/ssaoPart'
SsaoBlurPart = require './shader/ssaoBlurPart'
log = require 'loglevel'

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
		@useBigPipelineTargets = false
		@usePipelineSsao = false

	localRenderer: (timestamp) =>
		# Clear screen
		@threeRenderer.context.stencilMask(0xFF)
		@threeRenderer.clear()

		# Render the default scene (plugins add objects in the init3d hook)
		@threeRenderer.render @scene, @camera

		# Allow for custom render passes
		if @pipelineEnabled
			# Init render target
			@_initializePipelineTarget()

			# Clear render target
			@threeRenderer.setRenderTarget(@pipelineRenderTarget.renderTarget)
			@threeRenderer.context.stencilMask(0xFF)
			@threeRenderer.clear()
			@threeRenderer.setRenderTarget(null)

			# Set global config
			pipelineConfig = {
				useBigTargets: @useBigPipelineTargets
			}

			# Let plugins render in our target
			@pluginHooks.onPaint(
				@threeRenderer,
				@camera,
				@pipelineRenderTarget.renderTarget,
				pipelineConfig
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



		# Call update hook
		@pluginHooks.on3dUpdate timestamp
		@controls?.update()
		@animationRequestID = requestAnimationFrame @localRenderer

	# Create / update target for all pipeline passes
	_initializePipelineTarget: =>
		if not @pipelineRenderTarget? or
		not renderTargetHelper.renderTargetHasRightSize(
			@pipelineRenderTarget.renderTarget, @threeRenderer, @useBigPipelineTargets
		)
			# Create the render target that renders everything antialiased to the screen
			shaderParts = []
			if @usePipelineFxaa
				shaderParts.push new FxaaShaderPart()

			@pipelineRenderTarget = renderTargetHelper.createRenderTarget(
				@threeRenderer,
				shaderParts,
				{},
				1.0,
				@useBigPipelineTargets
			)

			if @usePipelineSsao
				# Get a random texture for SSAO
				randomTex = THREE.ImageUtils.loadTexture('img/randomTexture.png')
				randomTex.wrapS = THREE.RepeatWrapping
				randomTex.wrapT = THREE.RepeatWrapping

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
		if @pipelineEnabled
			# Determine whether to use bigger render targets (super sampling)
			if fidelityLevel >= availableLevels.indexOf 'PipelineHigh'
				@useBigPipelineTargets = true
			else
				@useBigPipelineTargets = false

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

			# Determine wether to use SSAO
			if fidelityLevel >= availableLevels.indexOf 'PipelineUltra'
				# Only do something when SSAO is not already used
				if not @usePipelineSsao
					@usePipelineSsao = true
					@pipelineRenderTarget = null
			else
				if @usePipelineSsao
					@usePipelineSsao = false
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

	zoomToBoundingSphere: (radiusAndPosition) ->
		# Zooms out/in the camera so that the object is fully visible
		radius = radiusAndPosition.radius
		center = radiusAndPosition.center
		center = new THREE.Vector3(center.x, center.y, center.z)

		alpha = @camera.fov
		distanceToObject = radius / Math.sin(alpha)

		rv = @camera.position.clone().sub(@controls.target)
		rv = rv.normalize().multiplyScalar(distanceToObject)
		zoomAdjustmentFactor = 2.5
		rv = rv.multiplyScalar(zoomAdjustmentFactor)

		# Apply scene transforms (e.g. rotation to make y the vector facing upwards)
		target = center.clone().applyMatrix4(@scene.matrix)
		position = target.clone().add(rv)
		@setCamera position, target

	setCamera: (position, target) ->
		@controls.update()
		@controls.target = @controls.target0 =
			new THREE.Vector3(target.x, target.y, target.z)
		@controls.position = @controls.position0 =
			new THREE.Vector3(position.x, position.y, position.z)
		@controls.reset()

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

		# Scene rotation because orbit controls only works
		# with up vector of 0, 1, 0
		sceneRotation = new THREE.Matrix4()
		sceneRotation.makeRotationAxis(
			new THREE.Vector3( 1, 0, 0 ),
			(-Math.PI / 2)
		)
		scene.applyMatrix(sceneRotation)
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
			globalConfig.axisLength + 10
			globalConfig.axisLength / 2
		)
		@camera.up.set(0, 1, 0)
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
