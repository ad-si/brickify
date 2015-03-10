###
  #Lego Board Plugin#

  Creates a lego board as a workspace surface to help people align models
  to the lego grid
###

THREE = require 'three'
modelCache = require '../../client/modelCache'
globalConfig = require '../../common/globals.yaml'


module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		return

	# Load the board
	init3d: (@threejsNode) =>
		@highQualMode = true

		knobTexture = THREE.ImageUtils.loadTexture('img/baseplateStud.png')
		knobTexture.wrapS = THREE.RepeatWrapping
		knobTexture.wrapT = THREE.RepeatWrapping
		knobTexture.repeat.set 50,50

		@baseplateMaterial = new THREE.MeshLambertMaterial(
			color: globalConfig.colors.basePlate
		)
		@baseplateTexturedMaterial = new THREE.MeshLambertMaterial(
			map: knobTexture
		)
		@currentBaseplateMaterial = @baseplateMaterial

		@baseplateTransparentMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlate
				opacity: 0.4
				transparent: true
		)
		knobsMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlateStud
		)

		#create baseplate
		box = new THREE.BoxGeometry(400, 400, 8)
		boxobj = new THREE.Mesh(box, @baseplateMaterial)
		boxobj.translateZ -4
		@threejsNode.add boxobj

		#create knobs
		knobsContainer = new THREE.Object3D()
		@threejsNode.add knobsContainer

		modelCache
		.request('1336affaf837a831f6b580ec75c3b73a')
		.then (model) =>
			geo = model.convertToThreeGeometry()
			for x in [-160..160] by 80
				for y in [-160..160] by 80
					object = new THREE.Mesh(geo, knobsMaterial)
					object.translateX x
					object.translateY y
					knobsContainer.add object

	on3dUpdate: () =>
		# check if the camera is below z=0. if yes, make the plate transparent
		# and hide knobs
		if not @bundle?
			return

		cam = @bundle.renderer.camera

		# it should be z, but due to orbitcontrols the scene is rotated
		if cam.position.y < 0
			@threejsNode.children[0].material = @baseplateTransparentMaterial
			@threejsNode.children[1].visible = false
		else
			@threejsNode.children[0].material = @currentBaseplateMaterial
			@threejsNode.children[1].visible = true if @highQualMode

	toggleVisibility: () =>
		@threejsNode.visible = !@threejsNode.visible

	decreaseVisualQuality: () =>
		if @highQualMode
			@highQualMode = false

			#hide knobs
			@threejsNode.children[1].visible = false
			#change baseplate material to knob texture
			@threejsNode.children[0].material = @baseplateTexturedMaterial
			@currentBaseplateMaterial = @baseplateTexturedMaterial
		return false

	increaseVisualQuality: () =>
		if not @highQualMode
			@highQualMode = true
			
			#show knobs
			@threejsNode.children[1].visible = true
			#remove texture because we have physical knobs
			@threejsNode.children[0].material = @baseplateMaterial
			@currentBaseplateMaterial = @baseplateMaterial
		return false
