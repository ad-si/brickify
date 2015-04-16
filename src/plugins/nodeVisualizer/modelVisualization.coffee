THREE = require 'three'
threeHelper = require '../../client/threeHelper'
LineMatGenerator = require './visualization/LineMatGenerator'

class ModelVisualization
	constructor: (@globalConfig, @node, threeNode) ->
		@_initializeMaterials()

		@threeNode = new THREE.Object3D()
		threeNode.add @threeNode

	createVisualization: ->
		@_createVisualization(@node, @threeNode)

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

	_initializeMaterials: =>
		@objectMaterial = new THREE.MeshLambertMaterial({
			color: @globalConfig.colors.modelColor
			opacity: @globalConfig.colors.modelOpacity
			transparent: @globalConfig.colors.modelOpacity < 1.0
		})

		@shadowMat = new THREE.MeshBasicMaterial(
			color: @globalConfig.colors.modelShadowColor
			opacity: @globalConfig.colors.modelShadowOpacity
			transparent: @globalConfig.colors.modelShadowOpacity < 1.0
			depthFunc: THREE.GreaterDepth
		)

		# remove z-Fighting on baseplate
		@objectMaterial.polygonOffset = true
		@objectMaterial.polygonOffsetFactor = 3
		@objectMaterial.polygonOffsetUnits = 3
		@shadowMat.polygonOffset = true
		@shadowMat.polygonOffsetFactor = 3
		@shadowMat.polygonOffsetUnits = 3

		lineMaterialGenerator = new LineMatGenerator()
		@lineMat = lineMaterialGenerator.generate 0x000000
		@lineMat.linewidth = 2
		@lineMat.transparent = true
		@lineMat.opacity = 0.1
		@lineMat.depthFunc = THREE.GreaterDepth
		@lineMat.depthWrite = false

	_createVisualization: (node, threejsNode) =>
		unless @globalConfig.showModel
			@afterCreationPromise = node.getModel()
			return @afterCreationPromise
		_addSolid = (geometry, parent) =>
			solid = new THREE.Mesh geometry, @objectMaterial
			parent.add solid
			parent.solid = solid

		_addWireframe = (geometry, parent) =>
			# ToDo: create fancy shader material / correct rendering pipeline
			wireframe = new THREE.Object3D()

			#shadow
			shadow = new THREE.Mesh geometry, @shadowMat
			wireframe.add shadow

			# visible black lines
			lineObject = new THREE.Mesh geometry
			lines = new THREE.EdgesHelper lineObject, 0x000000, 30
			lines.material = @lineMat
			wireframe.add lines

			parent.add wireframe
			parent.wireframe = wireframe

		_addModel = (model) =>
			geometry = model.convertToThreeGeometry()

			_addSolid geometry, @threeNode
			_addWireframe geometry, @threeNode if @globalConfig.createVisibleWireframe

			threeHelper.applyNodeTransforms node, @threeNode

		@afterCreationPromise = node.getModel().then _addModel
		return @afterCreationPromise

module.exports = ModelVisualization
