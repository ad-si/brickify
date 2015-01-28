###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
objectTree = require '../../common/state/objectTree'
modelCache = require '../../client/modelCache'

module.exports = class SolidRenderer

	init: (bundle) ->
		@globalConfig = bundle.globalConfig

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
				return Promise.resolve()
		else
			node.pluginData.solidRenderer = {}
			return @loadModelFromCache node, node.pluginData.solidRenderer, false

	loadModelFromCache: (node, properties, reload = false) ->
		#Create object and override name
		success = (optimizedModel) =>
			console.log "Got model #{node.meshHash}"
			threeObj = @addModelToThree optimizedModel
			if reload
				threeObj.name = properties.threeObjectUuid
			else
				properties.threeObjectUuid = threeObj.name
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
				color: @globalConfig.defaultObjectColor
				ambient: @globalConfig.defaultObjectColor
			}
		)
		object = new THREE.Mesh(geometry, objectMaterial)
		object.name = object.uuid
		@latestAddedObject = object

		@threejsNode.add object
		return object

	newBoundingSphere: () =>
		if @latestAddedObject
			@latestAddedObject.geometry.computeBoundingSphere()
			result =
				radius: @latestAddedObject.geometry.boundingSphere.radius
				center: @latestAddedObject.geometry.boundingSphere.center
			@latestAddedObject = null
			return result
		else
			return null

	# copys stored transforms to the tree object.
	# TODO: use
	copyTransformDataToThree: (node, threeObject) ->
		posd = node.positionData
		threeObject.position.set(posd.position.x, posd.position.y, posd.position.z)
		threeObject.rotation.set(
			posd.rotation._x,
			posd.rotation._y,
			posd.rotation._z
		)
		threeObject.scale.set(posd.scale.x, posd.scale.y, posd.scale.z)
