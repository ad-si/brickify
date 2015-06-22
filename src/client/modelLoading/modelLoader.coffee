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

	loadByHash: (hash) =>
		modelCache
		.request hash
		.then (model) => @_load model, hash
		.catch (error) ->
			log.error "Could not load model from hash #{hash}"
			log.error error.stack

	_load: (model, hash) =>
		return model
			.done()
			.then =>
				fileName = model.model.fileName
				@_addModelToScene fileName, hash, model

	# adds a new model to the state
	_addModelToScene: (fileName, hash, model) ->
		model
			.getAutoAlignMatrix()
			.then (matrix) =>
				node = new Node
					name: fileName
					modelHash: hash
					transform:
						position:
							x: matrix[0][3]
							y: matrix[1][3]
							z: matrix[2][3]

				@bundle.sceneManager.add node

module.exports = ModelLoader
