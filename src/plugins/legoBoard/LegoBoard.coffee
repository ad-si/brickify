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
		@_belowPlate = false
		return

	# Load the board
	init3d: (@threejsNode) =>
		@baseplateMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlate
		)
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
			if not @_belowPlate
				@_belowPlate = true
				@threejsNode.children[0].material = @baseplateTransparentMaterial
				@threejsNode.children[1].visible = false
		else
			if @_belowPlate
				@_belowPlate = false
				@threejsNode.children[0].material = @baseplateMaterial
				@threejsNode.children[1].visible = true

	toggleVisibility: () =>
		@threejsNode.visible = !@threejsNode.visible
