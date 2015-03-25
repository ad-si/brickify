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

module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		return

	# Load the board (in separate scene to be rendered in custom render pass)
	init3d: (@threejsNode) =>
		@boardScene = @bundle.renderer.getDefaultScene()

		@highQualMode = false

		studTexture = THREE.ImageUtils.loadTexture('img/baseplateStud.png')
		studTexture.wrapS = THREE.RepeatWrapping
		studTexture.wrapT = THREE.RepeatWrapping
		studTexture.repeat.set 50,50

		@baseplateMaterial = new THREE.MeshLambertMaterial(
			color: globalConfig.colors.basePlate
		)
		@baseplateTexturedMaterial = new THREE.MeshLambertMaterial(
			map: studTexture
		)

		studMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlateStud
		)

		#create baseplate
		box = new THREE.BoxGeometry(400, 400, 8)
		boxobj = new THREE.Mesh(box, @baseplateTexturedMaterial)
		boxobj.translateZ -4
		@boardScene.add boxobj
		@boardScene.baseplate = boxobj

		#create studs
		studsContainer = new THREE.Object3D()
		@boardScene.add studsContainer
		@boardScene.studs = studsContainer
		studsContainer.visible = false

		modelCache
		.request('1336affaf837a831f6b580ec75c3b73a')
		.then (model) =>
			geo = model.convertToThreeGeometry()
			for x in [-160..160] by 80
				for y in [-160..160] by 80
					object = new THREE.Mesh(geo, studMaterial)
					object.translateX x
					object.translateY y
					studsContainer.add object

	onPaint: (threeRenderer, camera) =>
		# recreate textures if either they havent been generated yet or
		# the screen size has changed
		if not (@renderTargetsInitialized? and
		RenderTargetHelper.renderTargetHasRightSize(
			@boardSceneTarget.renderTarget, threeRenderer
		))
			@boardSceneTarget = RenderTargetHelper.createRenderTarget(threeRenderer)
			@renderTargetsInitialized = true

		#render board
		threeRenderer.render @boardScene, camera, @boardSceneTarget.renderTarget, true

		gl = threeRenderer.context

		# render baseplate transparent if cam looks from below
		if camera.position.y < 0
			# one fully transparent render pass
			@boardSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4
			threeRenderer.render @boardSceneTarget.quadScene, camera
		else
			# one default opaque pass
			@boardSceneTarget.blendingMaterial.uniforms.opacity.value = 1
			threeRenderer.render @boardSceneTarget.quadScene, camera

			#render one pass transparent, where visible object or shadow is
			# (= no lego)
			gl.enable(gl.STENCIL_TEST)
			gl.stencilFunc(gl.EQUAL, 0x00, stencilBits.legoMask)
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)
			gl.stencilMask(0x00)

			@boardSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4

			gl.disable(gl.DEPTH_TEST)
			threeRenderer.render @boardSceneTarget.quadScene, camera
			gl.enable(gl.DEPTH_TEST)

			gl.disable(gl.STENCIL_TEST)

	toggleVisibility: =>
		@boardScene.visible = !@boardScene.visible

	uglify: =>
		if @highQualMode
			@highQualMode = false

			#hide studs
			@boardScene.studs.visible = false
			#change baseplate material to stud texture
			@boardScene.baseplate.material = @baseplateTexturedMaterial
			return true

		return false

	beautify: =>
		if not @highQualMode
			@highQualMode = true

			#show studs
			@boardScene.studs.visible = true
			#remove texture because we have physical studs
			@boardScene.baseplate.material = @baseplateMaterial
			return true

		return false
