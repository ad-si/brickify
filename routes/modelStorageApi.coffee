modelStorage = require '../src/server/modelStorage'
md5 = require('blueimp-md5').md5
logger = require 'winston'

module.exports.modelExists = (request, response) ->
	hash = request.params.hash
	modelStorage.hasModel hash, (hasModel) ->
		if hasModel
			logger.debug 'Model ' + hash + ' exists'
			response.status(200).send('Model exists')
		else
			logger.debug 'Model ' + hash + ' does not exist'
			response.status(404).send('Model does not exist')

module.exports.getModel = (request, response) ->
	hash = request.params.hash
	modelStorage.hasModel hash, (hasModel) ->
		if hasModel
			modelStorage.loadModel(hash)
			.then((data) ->
				logger.debug 'Sending model ' + hash
				response.set 'Content-Type', 'application/octet-stream'
				response.send data
			)
			.catch((error) ->
				logger.warn 'Unable to load model ' +
					hash + ': ' + JSON.stringify(error)
				response.status(500).send error
			)
		else
			logger.warn 'Unable to load model ' +
				hash + ': model not found'
			response.status(404).send 'Model not found'

module.exports.saveModel = (request, response) ->
	hash = request.params.hash
	content = request.body
	calculatedMd5 = md5 content

	if hash isnt calculatedMd5
		response.status(500).send 'Calculated MD5 value does not match'
	else
		logger.debug 'Saving model ' + hash
		modelStorage.saveModel hash, content
		.then -> response.send 'Saved model'
		.catch -> response.status(500).send 'Error while saving the file'
