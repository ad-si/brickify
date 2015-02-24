###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
threeHelper = require '../../client/threeHelper'
modelCache = require '../../client/modelCache'

class SolidRenderer
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		@loadedModelsNodes = []
		@objectMaterial = new THREE.MeshLambertMaterial(
			color: @globalConfig.colors.object
			ambient: @globalConfig.colors.object
		)

	init3d: (@threejsNode) ->
		return

	onNodeAdd: (node) =>
		_addModel = (model) =>
			geometry = model.convertToThreeGeometry()
			object = new THREE.Mesh geometry, @objectMaterial
			threeHelper.link node, object
			threeHelper.applyNodeTransforms node, object
			@threejsNode.add object
		node.getModel().then _addModel

	onNodeRemove: (node) =>
		@threejsNode.remove threeHelper.find node, @threejsNode

	newBoundingSphere: () =>
		if @latestAddedObject
			@latestAddedObject.geometry.computeBoundingSphere()
			result =
				radius: @latestAddedObject.geometry.boundingSphere.radius
				center: @latestAddedObject.geometry.boundingSphere.center
			
			# update center to match moved object
			@latestAddedObject.updateMatrix()
			result.center.applyProjection @latestAddedObject.matrix

			@latestAddedObject = null
			return result
		else
			return null

	setNodeVisibility: (node, visible) =>
		threeHelper.find(node, @threejsNode)?.visible = visible

	setNodeMaterial: (node, threeMaterial) =>
		threeHelper.find(node, @threejsNode)?.material = threeMaterial

module.exports = SolidRenderer
