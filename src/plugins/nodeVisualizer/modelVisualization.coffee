THREE = require 'three'
threeHelper = require '../../client/threeHelper'
LineMatGenerator = require './visualization/LineMatGenerator'
threeConverter = require '../../client/threeConverter'
log = require 'loglevel'


class ModelVisualization
	constructor: (@globalConfig, @node, threeNode) ->
		@ready = Promise
		.resolve()
		.then =>
			@objectMaterial = new THREE.MeshLambertMaterial({
				color: @globalConfig.colors.modelColor
				opacity: @globalConfig.colors.modelOpacity
				transparent: @globalConfig.colors.modelOpacity < 1.0
				polygonOffset: true
				polygonOffsetFactor: 3
				polygonOffsetUnits: 3
			})

			@shadowMat = new THREE.MeshBasicMaterial(
				color: @globalConfig.colors.modelShadowColor
				opacity: @globalConfig.colors.modelShadowOpacity
				transparent: @globalConfig.colors.modelShadowOpacity < 1.0
				depthFunc: THREE.GreaterDepth
				polygonOffset: true
				polygonOffsetFactor: 3
				polygonOffsetUnits: 3
			)

			lineMaterialGenerator = new LineMatGenerator()
			@lineMat = lineMaterialGenerator.generate 0x000000
			@lineMat.linewidth = 2
			@lineMat.transparent = true
			@lineMat.opacity = 0.1
			@lineMat.depthFunc = THREE.GreaterDepth
			@lineMat.depthWrite = false

			@threeNode = new THREE.Object3D()
			threeNode.add @threeNode

		return @


	createVisualization: =>
		return @next => @_createVisualization @node, @threeNode

	setSolidMaterial: (material) =>
		return @next => @threeNode.solid?.material = material

	setNodeVisibility: (visible) =>
		return @next => @threeNode.visible = visible

	setShadowVisibility: (visible) =>
		return @next => @threeNode.wireframe?.visible = visible

	getSolid: =>
		return @done =>
			return @threeNode.solid


	_addSolid: (geometry, parent) =>
		solid = new THREE.Mesh geometry, @objectMaterial
		parent.add solid
		parent.solid = solid


	_addWireframe: (geometry, parent) =>
		# ToDo: create fancy shader material / correct rendering pipeline
		wireframe = new THREE.Object3D()

		# Shadow
		shadow = new THREE.Mesh geometry, @shadowMat
		wireframe.add shadow

		# Visible black lines
		lineObject = new THREE.Mesh geometry
		lines = new THREE.EdgesHelper lineObject, 0x000000, 30
		lines.material = @lineMat
		wireframe.add lines

		parent.add wireframe
		parent.wireframe = wireframe


	_createVisualization: (node, threejsNode) =>
		if not @globalConfig.showModel
			return node.getModel()
		else
			return node
			.getModel()
			.then (model) =>
				return model.getObject()
			.then (modelObject) =>
				geometry = threeConverter.toStandardGeometry modelObject

				threeHelper.applyNodeTransforms node, threejsNode

				@_addSolid geometry, threejsNode

				if @globalConfig.createVisibleWireframe
					@_addWireframe geometry, threejsNode

				return threejsNode.solid
			.catch (error) =>
				log.error error


	next: (onFulfilled, onRejected) =>
		@done onFulfilled, onRejected
		return @

	done: (onFulfilled, onRejected) =>
		onFulfilledTemp = => onFulfilled? @model
		@ready = @ready.then onFulfilledTemp, onRejected
		return @ready

	catch: (onRejected) =>
		@ready = @ready.catch onRejected
		return @ready

module.exports = ModelVisualization
