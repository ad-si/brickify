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

	loadFromIdentifier: (identifier) =>
		modelCache
		.request identifier
		.then (model) => @_load model, identifier
		.catch (error) ->
			log.error "Could not load model #{identifier}"
			log.error error.stack

	_load: (model, identifier) =>
		return model
			.done()
			.then =>
				fileName = model.model.fileName
				@_addModelToScene fileName, identifier, model

	# adds a new model to the state
	_addModelToScene: (fileName, identifier, model) ->
		model
			.getAutoAlignMatrix()
			.then (matrix) =>
				node = new Node
					name: fileName
					modelIdentifier: identifier
					transform:
						position:
							x: matrix[0][3]
							y: matrix[1][3]
							z: matrix[2][3]

				@bundle.sceneManager.add node

module.exports = ModelLoader
