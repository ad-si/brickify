common = require '../../../common/pluginCommon'
objectTree = require '../../../common/objectTree'
stlLoader = require './stlLoader'
modelCache = require '../../modelCache'
OptimizedModel = require '../../../common/OptimizedModel'

stateSync = require '../../statesync'

threejsRootNode = null
globalConfigInstance = null

pluginPropertyName = 'stlImport'
class StlProperty
	constructor: () ->
		@threeObjectUuid = ''
		# DO NOT use as identifier
		@fileName = ''
		# DO use as identifier
		@meshHash = ''
		@positionData =
			position: null
			rotation: null
			scale: null

module.exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig

module.exports.init3d = (threejsNode) ->
  threejsRootNode = threejsNode

# check if there are any threejs objects that haven't been loaded yet
# if so, load the referenced model from the server
module.exports.onStateUpdate = (delta, state) ->
	objectTree.forAllSubnodeProperties state.rootNode,
		pluginPropertyName, (property) ->
			storedUuid = property.threeObjectUuid
			threeObject = threejsRootNode.getObjectById storedUuid, true
			if not threeObject?
				loadModelFromCache property

loadModelFromCache = (property) ->
	#Create object and override uuid
	success = (optimizedModel) ->
		console.log "Got the model #{property.meshHash} from the server"
		threeObj = addModelToThree optimizedModel
		stateSync.performStateAction (state) ->
			copyPropertyDataToThree property, threeObj
	failure = () ->
		console.error "Unable to get model #{property.meshHash} from server"

	modelCache.requestOptimizedMeshFromServer property.meshHash, success, failure

# Imports the stl, optimizes it,
# sends it to the server (if not cached there)
# and adds it to the scene as a THREE.Geometry
module.exports.importFile = (fileName, fileContent) ->
	errorCallback = (errors) ->
		console.error 'Errors occured while importing the stl file:'
		for error in errors
			console.error '-> ' + error
	optimizedModel = stlLoader.parse fileContent, errorCallback, true, true

	# happens with empty files
	if !optimizedModel
		return

	optimizedModel.originalFileName = fileName

	base64Optimized = optimizedModel.toBase64()
	md5hash = md5(base64Optimized)
	threeObject = addModelToThree optimizedModel
	fileEnding = 'optimized'
	addModelToState optimizedModel.originalFileName,
		md5hash + '.' + fileEnding, threeObject
	modelCache.submitMeshToServer md5hash, fileEnding, base64Optimized
	return optimizedModel

# Loads an hash from the server and adds it to the state / three-geometry
module.exports.importHash = (md5HashWithEnding) ->
	successCallback = (optimizedModel) ->
		threeObject = addModelToThree optimizedModel
		addModelToState optimizedModel.originalFileName,
			md5HashWithEnding, threeObject
	failCallback = () ->
		console.warn "Unable to load hash #{md5HashWithEnding} from Server"

	modelCache.requestOptimizedMeshFromServer md5HashWithEnding,
		successCallback, failCallback

# adds a new model to the state
addModelToState = (fileName, md5HashWithEnding, threeObject) ->
	if stateSync?
		loadModelCallback = (state) ->
			node = objectTree.addChild state.rootNode
			property = new StlProperty()
			objectTree.addPluginData node, pluginPropertyName, property
			property.fileName = fileName
			property.meshHash = md5HashWithEnding
			copyThreeDataToProperty property, threeObject
		# call updateState on all client plugins and sync
		stateSync.performStateAction loadModelCallback, true

# parses the binary geometry and adds it to the three scene,
# returning the uuid of the three object
addModelToThree = (optimizedModel) ->
	geometry = stlLoader.convertToThreeGeometry optimizedModel, false
	objectMaterial = new THREE.MeshLambertMaterial(
		{
			color: globalConfigInstance.defaultObjectColor
			ambient: globalConfigInstance.defaultObjectColor
		}
	)
	object = new THREE.Mesh( geometry, objectMaterial )
	threejsRootNode.add( object )
	return object

# Copys Three data (transforms, UUID) to the property object
copyThreeDataToProperty = (property, threeObject) ->
	property.threeObjectUuid = threeObject.uuid
	property.positionData.position = {x: null, y: null, z: null}
	property.positionData.position.x = threeObject.position.x
	property.positionData.position.y = threeObject.position.y
	property.positionData.position.z = threeObject.position.z

	property.positionData.rotation = {_x: null, _y: null, _z: null}
	property.positionData.rotation._x = threeObject.rotation._x
	property.positionData.rotation._y = threeObject.rotation._y
	property.positionData.rotation._z = threeObject.rotation._z

	property.positionData.scale = {x: null, y: null, z: null}
	property.positionData.scale.x = threeObject.scale.x
	property.positionData.scale.y = threeObject.scale.y
	property.positionData.scale.z = threeObject.scale.z

# copys stored transforms and UUID from the property to the tree object.
copyPropertyDataToThree = (property, threeObject) ->
	posd = property.positionData
	threeObject.uuid =  property.threeObjectUuid
	threeObject.position.set(posd.position.x, posd.position.y, posd.position.z)
	threeObject.rotation.set(
		posd.rotation._x,
		posd.rotation._y,
		posd.rotation._z
	)
	threeObject.scale.set(posd.scale.x, posd.scale.y, posd.scale.z)
