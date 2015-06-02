###
# @module modelLoader
###

md5 = require('blueimp-md5').md5
log = require 'loglevel'

modelCache = require './modelCache'
Node = require '../../common/project/node'

###
# @class ModelLoader
###
class ModelLoader
	constructor: (@bundle) ->
		return

	readFiles: (files) ->
		@readFile file for file in files

	readFile: (file) ->
		reader = new FileReader()
		reader.readAsArrayBuffer file
		reader.onload = =>
			fileBuffer = reader.result
			@importFile file.name, fileBuffer, (error, model) =>
				if error or not model
					throw error
				else
					@load model

	importFile: (filename, fileBuffer, callback) ->
		# Load with first plugin capable of loading the file
		for loader in @bundle.pluginHooks.get 'importFile'
			loader filename, fileBuffer, (error, model) ->
				if error or not model
					callback error
				else
					callback null, model

	loadByHash: (hash) =>
		modelCache
		.request hash
		.catch (error) ->
			log.error "Could not load model from hash #{hash}"
			log.error error
		.then (model) =>
			model
			.buildFacesFromFaceVertexMesh()
			.getModificationInvariantTranslation()
			.then (translationMatrix) =>
				return new Node {
					name: model.model.fileName # Todo: Use promises to get fileName
					modelHash: hash
					transform:
						position: translationMatrix
				}
		.then (node) =>
			return @bundle.sceneManager.add node
		.catch (error) =>
			log.error error

module.exports = ModelLoader
