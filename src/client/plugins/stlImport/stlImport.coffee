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
		@meshHash = ''
		@positionData =
			position: null
			rotation: null
			scale: null

module.exports.pluginName = 'stl Import Plugin'
module.exports.category = common.CATEGORY_IMPORT

module.exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig

module.exports.init3D = (threejsNode) ->
  threejsRootNode = threejsNode

# check if there are any threejs objects that haven't been loaded yet
# if so, load the referenced model from the server
module.exports.updateState = (delta, state) ->
	objectTree.forAllSubnodeProperties state.rootNode,
		pluginPropertyName, (property) ->
			storedUuid = property.threeObjectUuid
			threeObject = threejsRootNode.getObjectById storedUuid, true

			if not threeObject?
				#Create object and override uuid
				modelCache.requestOptimizedMeshFromServer property.meshHash,
					(optimizedModel) ->
						console.log "Got the model #{property.meshHash}
						from the server"
						newThreeObj = addModelToThree optimizedModel
						stateSync.performStateAction (state) ->
							copyPropertyDataToThree property, newThreeObj
					() ->
						console.log 'Unable to get model from server: ',
							property.meshHash

# Imports the stl, optimizes it,
# sends it to the server (if not cached there)
# and adds it to the scene as a THREE.Geometry
module.exports.importFile = (fileContent) ->
	errorCallback = (errors) ->
		console.log 'Errors occured while importing the stl file:'
		for error in errors
			console.log '-> ' + error
	optimizedModel = stlLoader.parse fileContent, errorCallback, true, true
	base64Optimized = optimizedModel.toBase64()
	md5hash = md5(base64Optimized)
	threeObject = addModelToThree optimizedModel
	fileEnding = 'optimized'
	if stateSync?
		stateSync.performStateAction (state) ->
			node = objectTree.addChildNode state.rootNode
			property = new StlProperty()
			objectTree.addPluginData node, pluginPropertyName, property

			property.meshHash = md5hash + '.' + fileEnding
			copyThreeDataToProperty property, threeObject
	modelCache.submitMeshToServer md5hash, fileEnding, base64Optimized

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
