###
  #Lego Board Plugin#

  Creates a lego board as a workspace surface to help people align models
  to the lego grid
###

THREE = require 'three'
modelCache = require '../../client/modelLoading/modelCache'
globalConfig = require '../../common/globals.yaml'
RenderTargetHelper = require '../../client/rendering/renderTargetHelper'
stencilBits = require '../../client/rendering/stencilBits'

dimension = 400

module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		return

	# Load the board
	init3d: (@threejsNode) =>
		@qualMode = 0
		@usePipeline = false
		@isVisible = true
		@isScreenshotMode = no

		@_initMaterials()
		@_initbaseplateBox()
		@_initStudGeometries()

		# create scene for pipeline
		@pipelineScene = @bundle.renderer.getDefaultScene()

	_initbaseplateBox: =>
		box = new THREE.BoxGeometry(dimension, dimension, 8)
		@baseplateBox = new THREE.Mesh(box, @baseplateMaterial)
		@baseplateBox.translateZ -4
		@threejsNode.add @baseplateBox

	_initStudGeometries: =>
		@studsContainer = new THREE.Object3D()
		@threejsNode.add @studsContainer
		@studsContainer.visible = false
		@_addStuds 7, @studsContainer

		@highFiStudsContainer = new THREE.Object3D()
		@threejsNode.add @highFiStudsContainer
		@highFiStudsContainer.visible = false
		@_addStuds 21, @highFiStudsContainer

	_addStuds: (radiusSegments, container) =>
		studGeometry = new THREE.CylinderGeometry(
			@globalConfig.studSize.radius
			@globalConfig.studSize.radius
			@globalConfig.studSize.height
			radiusSegments
		)
		rotation = new THREE.Matrix4()
		rotation.makeRotationX(1.571)
		studGeometry.applyMatrix(rotation)

		translation = new THREE.Matrix4()
		translation.makeTranslation 0, 0, @globalConfig.studSize.height / 2
		studGeometry.applyMatrix translation

		bufferGeometry = new THREE.BufferGeometry()
		bufferGeometry.fromGeometry studGeometry

		xSpacing = @globalConfig.gridSpacing.x
		ySpacing = @globalConfig.gridSpacing.y
		for x in [(-dimension + xSpacing) / 2...dimension / 2] by xSpacing
			for y in [(-dimension + ySpacing) / 2...dimension / 2] by ySpacing
				object = new THREE.Mesh(bufferGeometry, @studMaterial)
				object.translateX x
				object.translateY y
				container.add object

	_initMaterials: =>
		studTexture = THREE.ImageUtils.loadTexture('img/baseplateStud.png')
		studTexture.wrapS = THREE.RepeatWrapping
		studTexture.wrapT = THREE.RepeatWrapping
		studTexture.repeat.set dimension / 8, dimension / 8

		@baseplateMaterial = new THREE.MeshLambertMaterial(
			color: globalConfig.colors.basePlate
		)
		@baseplateTexturedMaterial = new THREE.MeshLambertMaterial(
			map: studTexture
		)
		@currentBaseplateMaterial = @baseplateTexturedMaterial

		@baseplateTransparentMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlate
				opacity: 0.4
				transparent: true
		)

		@studMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlateStud
		)

	on3dUpdate: =>
		# this check is only important if we don't use the pipeline
		return if @usePipeline or @isScreenshotMode

		# check if the camera is below z=0. if yes, make the plate transparent
		# and hide studs
		if not @bundle?
			return

		camera = @bundle.renderer.camera

		if camera.position.z < 0
			@baseplateBox.material = @baseplateTransparentMaterial
			@studsContainer.visible = false
			@highFiStudsContainer.visible = false
		else
			@baseplateBox.material = @currentBaseplateMaterial
			@studsContainer.visible = @qualMode is 1
			@highFiStudsContainer.visible = @qualMode is 2

	onPaint: (threeRenderer, camera, target) =>
		return if not @isVisible or @isScreenshotMode

		# recreate textures if either they havent been generated yet or
		# the screen size has changed
		if not (@renderTargetsInitialized? and
		RenderTargetHelper.renderTargetHasRightSize(
			@pipelineSceneTarget.renderTarget, threeRenderer
		))
			if @pipelineSceneTarget?
				RenderTargetHelper.deleteRenderTarget @pipelineSceneTarget, threeRenderer

			@pipelineSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer, null, null, 1.0
			)
			@renderTargetsInitialized = true

		#render board
		threeRenderer.render(
			@pipelineScene, camera, @pipelineSceneTarget.renderTarget, true
		)

		gl = threeRenderer.context

		# render baseplate transparent if cam looks from below
		if camera.position.z < 0
			# one fully transparent render pass
			@pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4
			threeRenderer.render @pipelineSceneTarget.quadScene, camera, target, false
		else
			# one default opaque pass
			@pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 1
			threeRenderer.render @pipelineSceneTarget.quadScene, camera, target, false

			#render one pass transparent, where visible object or shadow is
			# (= no lego)
			gl.enable(gl.STENCIL_TEST)
			gl.stencilFunc(gl.EQUAL, 0x00, stencilBits.legoMask)
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)
			gl.stencilMask(0x00)

			@pipelineSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4

			gl.disable(gl.DEPTH_TEST)
			threeRenderer.render @pipelineSceneTarget.quadScene, camera, target, false
			gl.enable(gl.DEPTH_TEST)

			gl.disable(gl.STENCIL_TEST)

	toggleVisibility: =>
		@threejsNode.visible = !@threejsNode.visible
		@isVisible = !@isVisible

	setFidelity: (fidelityLevel, availableLevels, options) =>
		if options.screenshotMode?
			@isScreenshotMode = options.screenshotMode
			@threejsNode.visible = @isVisible and not @isScreenshotMode

		# Determine whether to show or hide studs
		if fidelityLevel >= availableLevels.indexOf 'PipelineHigh'
			@qualMode = 2

			@highFiStudsContainer.visible = true
			@studsContainer.visible = false
			#remove texture because we have physical studs
			@baseplateBox.material = @baseplateMaterial

			@currentBaseplateMaterial = @baseplateMaterial

		if fidelityLevel > availableLevels.indexOf 'DefaultMedium'
			@qualMode = 1

			#show studs
			@studsContainer.visible = true
			@highFiStudsContainer.visible = false
			#remove texture because we have physical studs
			@baseplateBox.material = @baseplateMaterial

			@currentBaseplateMaterial = @baseplateMaterial
		else
			@qualMode = 0

			#hide studs
			@studsContainer.visible = false
			#change baseplate material to stud texture
			@baseplateBox.material = @baseplateTexturedMaterial

			@currentBaseplateMaterial = @baseplateTexturedMaterial

		# Determine whether to use the pipeline or not
		if fidelityLevel >= availableLevels.indexOf 'PipelineLow'
			if not @usePipeline
				@usePipeline = true

				#move lego board and studs from threeNode to pipeline scene
				@threejsNode.remove @baseplateBox
				@threejsNode.remove @studsContainer
				@threejsNode.remove @highFiStudsContainer

				@pipelineScene.add @baseplateBox
				@pipelineScene.add @studsContainer
				@pipelineScene.add @highFiStudsContainer
		else
			if @usePipeline
				@usePipeline = false

				#move lego board and studs from pipeline to threeNode
				@pipelineScene.remove @baseplateBox
				@pipelineScene.remove @studsContainer
				@pipelineScene.remove @highFiStudsContainer

				@threejsNode.add @baseplateBox
				@threejsNode.add @studsContainer
				@threejsNode.add @highFiStudsContainer
