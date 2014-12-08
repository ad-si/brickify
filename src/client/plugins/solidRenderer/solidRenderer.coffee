###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
objectTree = require '../../../common/objectTree'
modelCache = require '../../modelCache'

module.exports = class SolidRenderer

	init: (@globalConfig) ->
		return

	init3d: (@threejsNode) ->
		return

	# check if there are any threejs objects that haven't been loaded yet
	# if so, load the referenced model from the server
	onStateUpdate: (state, done) =>
		objectTree.forAllSubnodes state.rootNode, @loadModelIfNeeded, false

		#TODO: this is wrong, since loadModelIfneeded can modify the state
		#TODO: asynchronously. therefore done has to be called when all
		#TODO: loadModelIfNeeded calls are completed. Solve with promises
		done()

	loadModelIfNeeded: (node) =>
		if node.pluginData.solidRenderer?
			properties = node.pluginData.solidRenderer
			storedUuid = properties.threeObjectUuid
			threeObject = @threejsNode.getObjectByName storedUuid, true
			if not threeObject?
				@loadModelFromCache node, properties, true
		else
			node.pluginData.solidRenderer = {}
			@loadModelFromCache node, node.pluginData.solidRenderer, false
	# TODO: Remove deleted objects

	loadModelFromCache: (node, properties, reload = false) ->
		#Create object and override name
		success = (optimizedModel) =>
			console.log "Got model #{node.meshHash}"
			threeObj = @addModelToThree optimizedModel
			if reload
				threeObj.name = properties.threeObjectUuid
			else
				properties.threeObjectUuid = threeObj.name
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

		@threejsNode.add object
		return object

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
