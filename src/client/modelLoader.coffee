###
# @module fileLoader
###

pluginHooks = require '../common/pluginHooks'
modelCache = require './modelCache'
stateSync = require './statesync'
objectTree = require '../common/objectTree'

module.exports.readFiles = (files, stateInstance) ->
		readFile file, stateInstance for file in files

readFile = (file, stateInstance) ->
	reader = new FileReader()
	# TODO: remove extension check
	if file.name.toLowerCase().search '.stl' >= 0
		reader.onload = loadFile file.name, stateInstance
		reader.readAsBinaryString file

loadFile = (filename, stateInstance) -> (event) ->
	fileContent = event.target.result
	optimizedModel = importFile filename, fileContent
	load optimizedModel, stateInstance if optimizedModel?

importFile = (filename, fileContent) ->
	for loader in pluginHooks.get 'importFile'
		optimizedModel = loader filename, fileContent
		return optimizedModel if optimizedModel?

load = (optimizedModel, stateInstance) ->
	modelData = optimizedModel.toBase64()
	hash = md5(modelData)
	fileName = optimizedModel.originalFileName
	modelCache.store optimizedModel
	addModelToState fileName, hash, stateInstance
module.exports.load = load

module.exports.loadByHash = (hash, stateInstance) ->
	loadCallback = (optimizedModel) ->
		load optimizedModel, stateInstance

	modelCache.request hash, loadCallback,
		() -> console.error "Could not load model from hash #{hash}"

# adds a new model to the state
addModelToState = (fileName, hash, stateInstance) ->
	loadModelCallback = (state) ->
		node = objectTree.addChild state.rootNode
		node.fileName = fileName
		node.meshHash = hash
	# call updateState on all client plugins and sync
	stateInstance.performStateAction loadModelCallback, true
