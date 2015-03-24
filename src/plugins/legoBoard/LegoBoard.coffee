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

		# adjust rendering to camera position
		if camera.position.y < 0
			# hide knobs and render baseplate transparent if cam looks from below
			@boardScene.children[1].visible = false
			@boardSceneTarget.blendingMaterial.uniforms.opacity.value = 0.4
		else
			@boardScene.children[1].visible = true if @highQualMode
			@boardSceneTarget.blendingMaterial.uniforms.opacity.value = 1

		# render to texture
		threeRenderer.render @boardScene, camera, @boardSceneTarget.renderTarget, true
		# render texture to screen
		threeRenderer.render @boardSceneTarget.planeScene, camera

	toggleVisibility: =>
		@boardScene.visible = !@boardScene.visible

	uglify: =>
		if @highQualMode
			@highQualMode = false

			#hide studs
			@boardScene.children[1].visible = false
			#change baseplate material to stud texture
			@boardScene.children[0].material = @baseplateTexturedMaterial
			return true

		return false

	beautify: =>
		if not @highQualMode
			@highQualMode = true
			
			#show studs
			@boardScene.children[1].visible = true
			#remove texture because we have physical studs
			@boardScene.children[0].material = @baseplateMaterial
			return true
			
		return false
