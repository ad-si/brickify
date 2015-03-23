THREE = require 'three'
threeHelper = require '../../client/threeHelper'

class ModelVisualization
	constructor: (@globalConfig, @node, threeNode) ->
		@_initializeMaterials()

		@threeNode = new THREE.Object3D()
		threeNode.add @threeNode

	createVisualization: ->
		@_createVisualization(@node, @threeNode)
		
	setSolidMaterial: (material) =>
		@afterCreationPromise.then =>
			@threeNode.solid.material = material

	setNodeVisibility: (visible) =>
		@afterCreationPromise.then =>
			@threeNode.visible = visible

	setShadowVisibility: (visible) =>
		@afterCreationPromise.then =>
			@threeNode.wireframe.visible = visible

	afterCreation: =>
		return @afterCreationPromise

	getSolid: =>
		@threeNode.solid

	_initializeMaterials: =>
		@objectMaterial = new THREE.MeshLambertMaterial(
			color: @globalConfig.colors.object
			ambient: @globalConfig.colors.object
		)

		@lineMat = new THREE.MeshBasicMaterial({
			color: 0x000000
		})
	_createVisualization: (node, threejsNode) =>
		_addSolid = (geometry, parent) =>
			solid = new THREE.Mesh geometry, @objectMaterial
			parent.add solid
			parent.solid = solid

		_addWireframe = (geometry, parent) =>
			# visible black lines
			lineObject = new THREE.Mesh geometry
			lines = new THREE.EdgesHelper lineObject, 0x000000, 30
			lines.material = @lineMat

			parent.add lines
			parent.wireframe = lines

		_addModel = (model) =>
			geometry = model.convertToThreeGeometry()

			_addSolid geometry, @threeNode
			_addWireframe geometry, @threeNode if @globalConfig.createVisibleWireframe

			threeHelper.applyNodeTransforms node, @threeNode

		@afterCreationPromise = node.getModel().then _addModel
		return @afterCreationPromise

module.exports = ModelVisualization

