###
# @module fileLoader
###

pluginHooks = require '../common/pluginHooks'
modelCache = require './modelCache'
stateSync = require './statesync'
objectTree = require '../common/objectTree'

module.exports.readFiles = (files) ->
		readFile file for file in files

readFile = (file) ->
	reader = new FileReader()
	# TODO: remove extension check
	if file.name.toLowerCase().search '.stl' >= 0
		reader.onload = loadFile file.name
		reader.readAsBinaryString file

loadFile = (filename) -> (event) ->
	fileContent = event.target.result
	optimizedModel = importFile filename, fileContent
	load optimizedModel if optimizedModel?

importFile = (filename, fileContent) ->
	for loader in pluginHooks.get 'importFile'
		optimizedModel = loader filename, fileContent
		return optimizedModel if optimizedModel?

load = (optimizedModel) ->
	modelData = optimizedModel.toBase64()
	hash = md5(modelData)
	fileName = optimizedModel.originalFileName
	modelCache.store optimizedModel
	addModelToState fileName, hash
module.exports.load = load

module.exports.loadByHash = (hash) ->
	modelCache.request(hash).then(
		load
		() -> console.error "Could not load model from hash #{hash}"
	)

# adds a new model to the state
addModelToState = (fileName, hash) ->
	loadModelCallback = (state) ->
		node = objectTree.addChild state.rootNode
		node.fileName = fileName
		node.meshHash = hash
	# call updateState on all client plugins and sync
	stateSync.performStateAction loadModelCallback, true
