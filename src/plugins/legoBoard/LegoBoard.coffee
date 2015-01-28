###
  #Lego Board Plugin#

  Creates a lego board as a workspace surface to help people align models
  to the lego grid
###

THREE = require 'three'
modelCache = require '../../client/modelCache'

module.exports = class LegoBoard
	# Store the global configuration for later use by init3d
	init: (bundle) ->
		@globalConfig = bundle.globalConfig
		return

	# Load the board
	init3d: (@threejsNode) =>
		modelCache.request('ee2ce436d924c112de36e2bb6ff3a4cb').then (model) =>
			geo = model.convertToThreeGeometry()
			material = new THREE.MeshLambertMaterial(
				{
					color: 0xababab
					ambient: 0xbebebe
				}
			)
			for x in [-160..160] by 80
				for y in [-160..160] by 80
					object = new THREE.Mesh(geo, material)
					object.translateX x
					object.translateY y
					@threejsNode.add object

	toggleVisibility: () =>
		@threejsNode.visible = !@threejsNode.visible
