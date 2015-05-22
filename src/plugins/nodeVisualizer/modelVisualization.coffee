THREE = require 'three'
threeHelper = require '../../client/threeHelper'

class ModelVisualization
	constructor: (@globalConfig, @node, threeNode, @coloring) ->
		@threeNode = new THREE.Object3D()
		threeNode.add @threeNode

	createVisualization: ->
		@_createVisualization @node

	setSolidMaterial: (material) =>
		@afterCreationPromise.then =>
			@threeNode.solid?.material = material

	setNodeVisibility: (visible) =>
		@afterCreationPromise.then =>
			@threeNode.visible = visible

	setShadowVisibility: (visible) =>
		@afterCreationPromise.then =>
			@threeNode.wireframe?.visible = visible

	afterCreation: =>
		return @afterCreationPromise

	getSolid: =>
		@threeNode.solid

	_createVisualization: (node) =>

		_addSolid = (geometry, parent) =>
			solid = new THREE.Mesh geometry, @coloring.objectPrintMaterial
			parent.add solid
			parent.solid = solid

		_addWireframe = (geometry, parent) =>
			wireframe = new THREE.Object3D()

			#shadow
			shadow = new THREE.Mesh geometry, @coloring.objectShadowMat
			wireframe.add shadow

			# visible black lines
			lineObject = new THREE.Mesh geometry
			lines = new THREE.EdgesHelper lineObject, 0x000000, 30
			lines.material = @coloring.objectLineMat
			wireframe.add lines

			parent.add wireframe
			parent.wireframe = wireframe

		_addModel = (model) =>
			geometry = model.convertToThreeGeometry()

			if @globalConfig.rendering.showModel
				_addSolid geometry, @threeNode
			if @globalConfig.rendering.showShadowAndWireframe
				_addWireframe geometry, @threeNode

			threeHelper.applyNodeTransforms node, @threeNode

		@afterCreationPromise = node.getModel().then _addModel
		return @afterCreationPromise

module.exports = ModelVisualization
