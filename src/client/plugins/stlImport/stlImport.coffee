common = require '../../../common/pluginCommon'
objectTree = require '../../../common/objectTree'
stlLoader = require './stlLoader'
#stlLoader = new THREE.STLLoader()

threejsRootNode = null
stateInstance = null
globalConfigInstance = null

pluginPropertyName = "stlImport"
class StlProperty
	constructor: () ->
		@threeObjectUuid = ""
		@meshHash = ""
		@positionData =
			position: null
			rotation: null
			scale: null

module.exports.pluginName = 'stl Import Plugin'
module.exports.category = common.CATEGORY_IMPORT

module.exports.init = (globalConfig, state, ui) ->
	stateInstance = state
	globalConfigInstance = globalConfig

	#Bind to the fileLoader
	ui.fileReader.addEventListener(
		'loadend',
		handleDroppedFile.bind(@),
		false
	)

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
				requestMeshFromServer property.meshHash,
					(modelBinaryData) ->
						console.log "Got the model #{property.meshHash}
						from the server"
						newThreeObj = addModelToThree(modelBinaryData)
						stateInstance.performStateAction (state) ->
							copyPropertyDataToThree property, newThreeObj
					() ->
						console.log "Unable to get model from server: ",
							property.meshHash

# Add the model as a three model,
# send it to the server if it is not cached there
handleDroppedFile = (event) ->
	fileContent = event.target.result
	threeObject = addModelToThree fileContent
	md5hash = md5(event.target.result)
	fileEnding = 'stl'

	if stateInstance?
		stateInstance.performStateAction (state) ->
			node = objectTree.addChildNode state.rootNode
			property = new StlProperty()
			objectTree.addPluginData node, pluginPropertyName, property

			property.meshHash = md5hash + '.' + fileEnding
			copyThreeDataToProperty property, threeObject

	submitMeshToServer md5hash, fileEnding, fileContent

# parses the binary geometry and adds it to the three scene,
# returning the uuid of the three object
addModelToThree = (binary) ->
	stl = stlLoader.parse binary, (errors) ->
		console.log "Errors occured while importing the stl file:"
		for error in errors
			console.log "-> " + error

	geometry = stlLoader.convertToThreeGeometry stl, false
	objectMaterial = new THREE.MeshLambertMaterial(
		{
			color: globalConfigInstance.defaultObjectColor
			ambient: globalConfigInstance.defaultObjectColor
		}
	)
	object = new THREE.Mesh( geometry, objectMaterial )
	threejsRootNode.add( object )
	return object

# sends the model to the server if the server hasn't got a file
# with the same file ending and md5 value
submitMeshToServer = (md5hash, fileEnding, data) ->
	$.get('/model/exists/' + md5hash + '/' + fileEnding).fail () ->
		#server hasn't got the model, send it
		$.ajax '/model/submit/' + md5hash + '/' + fileEnding,
			data: data
			type: 'POST'
			contentType: 'application/octet-stream'
			success: () ->
				console.log 'sent model to the server'
			error: () ->
				console.log 'unable to send model to the server'

# requests a mesh with the given md5hash.ending from the server
requestMeshFromServer = (md5hashWithEnding, successCallback, failCallback) ->
	splitted = md5hashWithEnding.split('.')
	md5hash = splitted[0]
	fileEnding = splitted[1]
	$.get '/model/get/' + md5hash + '/' + fileEnding,
		"",
		(data, textStatus, jqXHR) ->
			successCallback(data)
	.fail () ->
		failCallback() if failCallback?

# Copys Three data (transforms, UUID) to the property object
copyThreeDataToProperty = (property, threeObject) ->
	property.threeObjectUuid = threeObject.uuid
	property.positionData.position = threeObject.position
	property.positionData.rotation = threeObject.rotation
	property.positionData.scale = threeObject.scale

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
