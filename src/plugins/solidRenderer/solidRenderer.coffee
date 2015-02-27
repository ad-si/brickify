###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
objectTree = require '../../common/state/objectTree'
modelCache = require '../../client/modelCache'
LineMatGenerator = require '../newBrickator/visualization/LineMatGenerator'
interactionHelper = require '../../client/interactionHelper'

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
			threeObject.originalMesh.associatedNode = node
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

		lineContainer = new THREE.Object3D()
		lineObject = new THREE.Mesh(geometry, objectMaterial)

		lineMaterialGen = new LineMatGenerator()

		#shadow
		shadowMat = new THREE.MeshBasicMaterial({
			color: 0x000000
			transparent: true
			opacity: 0.4
			})
		shadowMat.depthFunc = 'GREATER'
		shadowObject = new THREE.Mesh(geometry, shadowMat)
		lineContainer.add shadowObject

		# visible black lines
		lines = new THREE.EdgesHelper(lineObject, 0x000000, 30)
		lines.material = lineMaterialGen.generate(0x000000)
		lines.material.linewidth = 2
		lines.material.transparent = true
		lines.material.opacity = 0.1
		lines.material.depthFunc = 'GREATER'
		lines.material.depthWrite = false

		# ToDo: create fancy shader material / correct rendering pipeline
		lineContainer.add lines

		metaObject = new THREE.Object3D()
		metaObject.name = metaObject.uuid
		@latestAddedObject = metaObject
		
		metaObject.add object
		metaObject.originalMesh = object

		metaObject.add lineContainer
		metaObject.lineContainer = lineContainer

		@threejsNode.add metaObject
		return metaObject

	newBoundingSphere: () =>
		if @latestAddedObject
			geometry = @latestAddedObject.originalMesh.geometry
			geometry.computeBoundingSphere()
			result =
				radius: geometry.boundingSphere.radius
				center: geometry.boundingSphere.center

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

	_getThreeObjectByName: (name) =>
		for obj in @threejsNode.children
			if obj.name == name
				return obj
		return null

	toggleNodeVisibility: (node, visible) =>
		setVisibility = () =>
			obj = @_getThreeObjectByName node.pluginData.solidRenderer.threeObjectUuid
			if obj?
				obj.visible = visible

		@loadModelIfNeeded(node).then () =>
			setVisibility()

	setShadowVisibility: (node, visible) =>
		setVisibility = () =>
			obj = @_getThreeObjectByName node.pluginData.solidRenderer.threeObjectUuid
			if obj?
				obj.children[1].visible = visible

		@loadModelIfNeeded(node).then () =>
			setVisibility()

	setNodeMaterial: (node, threeMaterial) =>
		changeMaterial = () =>
			name = node.pluginData.solidRenderer.threeObjectUuid
			threeNode = @_getThreeObjectByName name

			if threeNode
				threeNode.originalMesh.material = threeMaterial

		@loadModelIfNeeded(node).then () =>
			changeMaterial()

	intersectRayWithModel: (event, node) =>
		obj = @_getThreeObjectByName node.pluginData.solidRenderer.threeObjectUuid
		return [] if not obj?

		# set two sided material to catch all sides
		visibleObject = obj.children[0]
		oldMaterialSide = visibleObject.material.side
		visibleObject.material.side = THREE.DoubleSide

		intersects =
			interactionHelper.getPolygonClickedOn(
				event
				[visibleObject]
				@bundle.renderer)

		visibleObject.material.side = oldMaterialSide

		return intersects
