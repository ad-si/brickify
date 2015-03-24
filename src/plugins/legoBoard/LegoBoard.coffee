###
  #Lego Board Plugin#

  Creates a lego board as a workspace surface to help people align models
  to the lego grid
###

THREE = require 'three'
modelCache = require '../../client/modelCache'
globalConfig = require '../../common/globals.yaml'
RenderTargetHelper = require '../../client/rendering/renderTargetHelper'

module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		return

	# Load the board (in seperate scene to be rendered in custom render pass)
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
		@currentBaseplateMaterial = @baseplateTexturedMaterial

		@baseplateTransparentMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlate
				opacity: 0.4
				transparent: true
		)
		studMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlateStud
		)

		#create baseplate
		box = new THREE.BoxGeometry(400, 400, 8)
		boxobj = new THREE.Mesh(box, @baseplateMaterial)
		boxobj.translateZ -4
		@boardScene.add boxobj

		#create studs
		studsContainer = new THREE.Object3D()
		@boardScene.add studsContainer
		studsContainer.visible = true

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

	customRenderPass: (threeRenderer, camera) =>
		if not @boardSceneTarget?
			@boardSceneTarget = RenderTargetHelper.createRenderTarget(threeRenderer)
		threeRenderer.render @boardScene, camera, @boardSceneTarget.renderTarget, true

		threeRenderer.render @boardSceneTarget.planeScene, camera

	on3dUpdate: =>
		return

		# check if the camera is below z=0. if yes, make the plate transparent
		# and hide studs
		if not @bundle?
			return

		cam = @bundle.renderer.camera

		# it should be z, but due to orbitcontrols the scene is rotated
		if cam.position.y < 0
			@boardScene.children[0].material = @baseplateTransparentMaterial
			@boardScene.children[1].visible = false
		else
			@boardScene.children[0].material = @currentBaseplateMaterial
			@boardScene.children[1].visible = true if @highQualMode

	toggleVisibility: =>
		@boardScene.visible = !@boardScene.visible

	uglify: =>
		if @highQualMode
			@highQualMode = false

			#hide studs
			@boardScene.children[1].visible = false
			#change baseplate material to stud texture
			@boardScene.children[0].material = @baseplateTexturedMaterial
			@currentBaseplateMaterial = @baseplateTexturedMaterial
			return true

		return false

	beautify: =>
		if not @highQualMode
			@highQualMode = true
			
			#show studs
			@boardScene.children[1].visible = true
			#remove texture because we have physical studs
			@boardScene.children[0].material = @baseplateMaterial
			@currentBaseplateMaterial = @baseplateMaterial
			return true
			
		return false
