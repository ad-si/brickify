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
	init: (bundle) ->
		@globalConfig = bundle.globalConfig
		return

	# Load the board
	init3d: (@threejsNode) =>
		material = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlate
		)
		knobsMaterial = new THREE.MeshLambertMaterial(
				color: globalConfig.colors.basePlateStud
		)

		#create baseplate
		box = new THREE.BoxGeometry(400, 400, 8)
		boxobj = new THREE.Mesh(box, material)
		boxobj.translateZ -4
		@threejsNode.add boxobj

		#create noppen
		modelCache
		.request('0de1cbfdc2710eeb3604aedb6c8853b7')
		.then (model) =>
			geo = model.convertToThreeGeometry()
			for x in [-160..160] by 80
				for y in [-160..160] by 80
					object = new THREE.Mesh(geo, knobsMaterial)
					object.translateX x
					object.translateY y
					@threejsNode.add object

	toggleVisibility: () =>
		@threejsNode.visible = !@threejsNode.visible
