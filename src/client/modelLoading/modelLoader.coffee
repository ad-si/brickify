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

	load: (model) =>
		return model
			.getBase64()
			.then (base64Model) =>
				hash = md5 base64Model
				fileName = model.model.fileName
				@addModelToScene fileName, hash, model

	loadByHash: (hash) =>
		modelCache
		.request hash
		.then @load
		.catch (error) ->
			log.error "Could not load model from hash #{hash}"
			log.error error.stack

	# adds a new model to the state
	addModelToScene: (fileName, hash, model) ->
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
