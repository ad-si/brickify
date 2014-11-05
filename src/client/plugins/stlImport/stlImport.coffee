common = require '../../../common/pluginCommon'
objectTree = require '../../../common/objectTree'

threejsRootNode = null
stlLoader = new THREE.STLLoader()
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

module.exports.init3d = (threejsNode) ->
  threejsRootNode = threejsNode

module.exports.needs3dAnimation = false
module.exports.update3d = (renderer) ->

module.exports.handleStateChange = (delta, state) ->
	#check if there are any threejs objects that haven't been loaded yet
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


handleDroppedFile = (event) ->
	fileContent = event.target.result
	threeObject = addModelToThree fileContent
	md5hash = md5(event.target.result)
	fileEnding = 'stl'

	stateInstance.performStateAction (state) ->
		node = objectTree.addChildNode state.rootNode
		property = new StlProperty()
		objectTree.addPluginData node, pluginPropertyName, property

		property.meshHash = md5hash + '.' + fileEnding
		copyThreeDataToProperty property, threeObject

	submitMeshToServer md5hash, fileEnding, fileContent

addModelToThree = (binary) ->
	#parses the binary geometry and adds it to the three scene,
	#returning the uuid of the three object
	geometry = stlLoader.parse binary
	objectMaterial = new THREE.MeshLambertMaterial(
		{
			color: globalConfigInstance.defaultObjectColor
			ambient: globalConfigInstance.defaultObjectColor
		}
	)
	object = new THREE.Mesh( geometry, objectMaterial )
	threejsRootNode.add( object )
	return object

submitMeshToServer = (md5hash, fileEnding, data) ->
	#sends the model to the server if the server hasn't got a file
	#with the same file ending and md5 value
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

copyThreeDataToProperty = (property, threeObject) ->
	property.threeObjectUuid = threeObject.uuid
	property.positionData.position = threeObject.position
	property.positionData.rotation = threeObject.rotation
	property.positionData.scale = threeObject.scale

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
