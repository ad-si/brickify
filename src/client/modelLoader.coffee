###
# @module modelLoader
###

md5 = require('blueimp-md5').md5
modelCache = require './modelCache'
objectTree = require '../common/objectTree'

module.exports = class ModelLoader
	constructor: (@stateInstance, @pluginHooks, @globalConfig) ->
		return

	readFiles: (files) ->
		@readFile file for file in files

	readFile: (file) ->
		reader = new FileReader()
		reader.readAsArrayBuffer file
		reader.onload = () =>
			fileBuffer = reader.result
			@importFile file.name, fileBuffer, (error, model) =>
				if error or not model
					throw error
				else
					@load model

	importFile: (filename, fileBuffer, callback) ->

		# Load with first plugin capable of loading
		loader = @pluginHooks.get('importFile')[0]

		loader filename, fileBuffer, (error, model) ->
			if error or not model
				callback error
			else
				callback null, model

	load: (model) =>
		modelData = model.toBase64()
		hash = md5(modelData)
		fileName = model.originalFileName
		modelCache.store model
		@addModelToState fileName, hash

	loadByHash: (hash) =>
		modelCache
		.request(hash)
		.then(@load)
		.catch (error) ->
			console.error "Could not load model from hash #{hash}"
			console.error error

	# adds a new model to the state
	addModelToState: (fileName, hash) ->
		loadModelCallback = (state) =>
			node = objectTree.addChild state.rootNode
			node.fileName = fileName
			node.meshHash = hash
			node.pluginData = {
				uiGen: {selectedPluginKey: @globalConfig.defaultPlugin}
			}
		# call updateState on all client plugins and sync
		@stateInstance.performStateAction loadModelCallback, true
