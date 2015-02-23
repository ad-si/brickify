###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
objectTree = require '../../common/state/objectTree'
modelCache = require '../../client/modelCache'
FancyLineMaterial = require '../newBrickator/visualization/FancyLineMaterial'

module.exports = class SolidRenderer

	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		@loadedModelsNodes = []

	init3d: (@threejsNode) ->
		return

	# check if there are any threejs objects that haven't been loaded yet
	# if so, load the referenced model from the server
	onStateUpdate: (state) =>
		@removeDeletedObjects state
		return Promise.all(
			objectTree.forAllSubnodes state.rootNode, @loadModelIfNeeded, false
		)

	removeDeletedObjects: (state) ->
		nodeUuids = []
		collectUuid = (node) =>
			if node.pluginData.solidRenderer?
				nodeUuids.push node.pluginData.solidRenderer.threeObjectUuid
		objectTree.forAllSubnodes state.rootNode, collectUuid, false
		threeUuids = @threejsNode.children.map (threenode) -> threenode.name
		deleted = threeUuids.filter (uuid) => uuid not in nodeUuids
		for d in deleted
			obj =  @threejsNode.getObjectByName d
			@threejsNode.remove obj

	loadModelIfNeeded: (node) =>
		if node.pluginData.solidRenderer?
			properties = node.pluginData.solidRenderer
			storedUuid = properties.threeObjectUuid
			threeObject = @threejsNode.getObjectByName storedUuid, true
			if not threeObject?
				return @loadModelFromCache node, properties, true
			else
				@_copyTransformDataToThree node, threeObject
				return Promise.resolve()
		else
			node.pluginData.solidRenderer = {}
			return @loadModelFromCache node, node.pluginData.solidRenderer, false

	loadModelFromCache: (node, properties, reload = false) ->
		#Create object and override name
		success = (optimizedModel) =>
			#prevent loading the same model twice
			if @loadedModelsNodes.indexOf(node) >= 0
				return Promise.resolve(optimizedModel)
			@loadedModelsNodes.push node

			console.log "Got model #{node.meshHash}"
			threeObject = @addModelToThree optimizedModel
			# enable Ui/mouseDispatcher find out on what node we clicked
			threeObject.associatedNode = node
			if reload
				threeObject.name = properties.threeObjectUuid
			else
				properties.threeObjectUuid = threeObject.name

			@_copyTransformDataToThree node, threeObject
			return optimizedModel
		failure = () ->
			console.error "Unable to get model #{node.meshHash}"

		prom = modelCache.request node.meshHash
		prom.catch failure
		return prom.then success

	# parses the binary geometry and adds it to the three scene
	addModelToThree: (optimizedModel) ->
		geometry = optimizedModel.convertToThreeGeometry()
		objectMaterial = new THREE.MeshLambertMaterial(
			{
				color: @globalConfig.colors.object
				ambient: @globalConfig.colors.object
			}
		)
		object = new THREE.Mesh(geometry, objectMaterial)
		object.name = object.uuid
		@latestAddedObject = object


		lineContainer = new THREE.Object3D()
		lineObject = new THREE.Mesh(geometry, objectMaterial)

		#todo: make this only write to depth buffer
		#invisible lines that make the black lines look better
		invisibleLines = new THREE.EdgesHelper(lineObject, 0x000000, 30)
		invisibleLineMat = new FancyLineMaterial()
		invisibleLines.material = invisibleLineMat.generate(0xffffff, 0.5)
		invisibleLines.material.linewidth = 9
		invisibleLines.material.colorWrite = false
		#lines.material.depthTest = false
		lineContainer.add invisibleLines

		# visible black lines
		lines = new THREE.EdgesHelper(lineObject, 0x000000, 30)
		linemat = new FancyLineMaterial()
		lines.material = linemat.generate(0x000000, 0.55)
		#lines.material.depthTest = false
		lineContainer.add lines
		
		@threejsNode.add object
		@threejsNode.add lineContainer

		return object

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

	_copyTransformDataToThree: (node, threeObject) ->
		posd = node.positionData
		threeObject.position.set posd.position.x, posd.position.y, posd.position.z
		threeObject.rotation.set(
			posd.rotation._x,
			posd.rotation._y,
			posd.rotation._z
		)
		threeObject.scale.set posd.scale.x, posd.scale.y, posd.scale.z

	getBrushes: =>
		return []
		###
		# deactivated until #250 is solved
		return [{
			text: 'move'
			iconBrush: true
			glyphicon: 'move'
			mouseDownCallback: @_handleMouseDown
			mouseMoveCallback: @_handleMouseMove
			mouseUpCallback: @_handleMouseUp
			tooltip: 'Move model'
		}]
		###

		###
		{
			text: 'rotate'
			iconBrush: true
			glyphicon: 'refresh'
			tooltip: 'Rotate model'
			#mouseDownCallback: @_handleMouseDown
			#mouseMoveCallback: @_handleMouseMove
			#mouseUpCallback: @_handleMouseUp
		}
		###

	_getThreeObjectByName: (name) =>
		for obj in @threejsNode.children
			if obj.name == name
				return obj
		return null

	_handleMouseDown: (event, selectedNode) =>
		@mouseStartPosition =
			@bundle.renderer.getGridPosition event.clientX, event.clientY

		@originalObjectPosition = selectedNode.positionData.position

	_handleMouseUp: (event, selectedNode) =>
		@mouseStartPosition = null
		return

	_handleMouseMove: (event, selectedNode) =>
		mouseCurrent = @bundle.renderer.getGridPosition event.clientX, event.clientY

		newPosition = {
			x: @originalObjectPosition.x + mouseCurrent.x - @mouseStartPosition.x
			y: @originalObjectPosition.y + mouseCurrent.y - @mouseStartPosition.y
			z: @originalObjectPosition.z
		}

		selectedNode.positionData.position = newPosition

		pld = selectedNode.pluginData.solidRenderer

		threeObject = @_getThreeObjectByName pld.threeObjectUuid
		@_copyTransformDataToThree selectedNode, threeObject

	toggleNodeVisibility: (node, visible) =>
		obj = @_getThreeObjectByName node.pluginData.solidRenderer.threeObjectUuid
		obj.visible = visible

	setNodeMaterial: (node, threeMaterial) =>
		changeMaterial = () =>
			name = node.pluginData.solidRenderer.threeObjectUuid
			threeNode = @_getThreeObjectByName name
			
			if threeNode
				threeNode.material = threeMaterial

		@loadModelIfNeeded(node).then () =>
			changeMaterial()
