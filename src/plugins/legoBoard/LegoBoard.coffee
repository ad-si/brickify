###
  #Lego Board Plugin#

  Creates a lego board as a workspace surface to help people align models
  to the lego grid
###

THREE = require 'three'
modelCache = require '../../client/modelLoading/modelCache'
globalConfig = require '../../common/globals.yaml'
threeConverter = require '../../client/threeConverter'


module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		return

	# Load the board
	init3d: (@threejsNode) =>
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
		@threejsNode.add boxobj

		#create studs
		studsContainer = new THREE.Object3D()
		@threejsNode.add studsContainer
		studsContainer.visible = false

		modelCache
		.request('1336affaf837a831f6b580ec75c3b73a')
		.then (model) ->
			return model.getObject()
		.then (modelObject) ->
			geometry = threeConverter.toStandardGeometry modelObject
			for x in [-160..160] by 80
				for y in [-160..160] by 80
					object = new THREE.Mesh(geometry, studMaterial)
					object.translateX x
					object.translateY y
					studsContainer.add object

	on3dUpdate: =>
		# check if the camera is below z=0. if yes, make the plate transparent
		# and hide studs
		if not @bundle?
			return

		cam = @bundle.renderer.camera

		# it should be z, but due to orbitcontrols the scene is rotated
		if cam.position.z < 0
			@threejsNode.children[0].material = @baseplateTransparentMaterial
			@threejsNode.children[1].visible = false
		else
			@threejsNode.children[0].material = @currentBaseplateMaterial
			@threejsNode.children[1].visible = true if @highQualMode

	toggleVisibility: =>
		@threejsNode.visible = !@threejsNode.visible

	setFidelity: (fidelityLevel, availableLevels) =>
		if fidelityLevel > availableLevels.indexOf 'DefaultMedium'
			@highQualMode = true

			#show studs
			@threejsNode.children[1].visible = true
			#remove texture because we have physical studs
			@threejsNode.children[0].material = @baseplateMaterial
			@currentBaseplateMaterial = @baseplateMaterial
		else
			@highQualMode = false

			#hide studs
			@threejsNode.children[1].visible = false
			#change baseplate material to stud texture
			@threejsNode.children[0].material = @baseplateTexturedMaterial
			@currentBaseplateMaterial = @baseplateTexturedMaterial
