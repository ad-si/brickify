common = require '../../common/pluginCommon'
objectTree = require '../../common/objectTree'

uiInstance = null
stlLoader = new THREE.STLLoader()
stateInstance = null
globalConfigInstance = null

module.exports.pluginName = 'stl Import Plugin'
module.exports.category = common.CATEGORY_IMPORT

module.exports.init = (ui, globalConfig, state) ->
	uiInstance = ui
	stateInstance = state
	globalConfigInstance = globalConfig

	#Bind to the fileLoader
	ui.fileReader.addEventListener(
		'loadend',
		handleDroppedFile.bind(@),
		false
	)

handleDroppedFile = (event) ->
	fileContent = event.target.result
	threeUuid = addModelToThree fileContent
	md5hash = md5(event.target.result)
	fileEnding = 'stl'

	stateInstance.performStateAction (state) ->
		node = objectTree.addChildNode(state.rootNode)
		node.meshHash = md5hash + '.' + fileEnding
		node.threeObjectUuid = threeUuid

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
	uiInstance.scene.add( object )
	return object.uuid

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

module.exports.handleStateChange = (delta, state) ->
	return 0
