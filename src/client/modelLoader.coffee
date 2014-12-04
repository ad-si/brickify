###
# @module fileLoader
###

md5 = require('blueimp-md5').md5
modelCache = require './modelCache'
objectTree = require '../common/objectTree'

module.exports = class ModelLoader
	constructor: (@stateInstance, @pluginHooks) ->
		return

	readFiles: (files) ->
		@readFile file for file in files

	readFile: (file) ->
		reader = new FileReader()
		# TODO: remove extension check
		if file.name.toLowerCase().search '.stl' >= 0
			reader.onload = @loadFile file.name
			reader.readAsBinaryString file

	loadFile: (filename) =>
		return (event) =>
			fileContent = event.target.result
			optimizedModel = @importFile filename, fileContent
			@load optimizedModel if optimizedModel?

	importFile: (filename, fileContent) ->
		for loader in @pluginHooks.get 'importFile'
			optimizedModel = loader filename, fileContent
			return optimizedModel if optimizedModel?

	load: (optimizedModel) ->
		modelData = optimizedModel.toBase64()
		hash = md5(modelData)
		fileName = optimizedModel.originalFileName
		modelCache.store optimizedModel
		@addModelToState fileName, hash

	loadByHash: (hash) ->
		loadCallback = (optimizedModel) ->
			@load optimizedModel

		modelCache.request hash, loadCallback,
			() -> console.error "Could not load model from hash #{hash}"

	# adds a new model to the state
	addModelToState: (fileName, hash) ->
		loadModelCallback = (state) ->
			node = objectTree.addChild state.rootNode
			node.fileName = fileName
			node.meshHash = hash
		# call updateState on all client plugins and sync
		@stateInstance.performStateAction loadModelCallback, true
