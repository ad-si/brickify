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
			modelStorage.loadModel hash, (error, data) ->
				if error?
					logger.warn 'Unable to load model ' +
						hash + ': ' + JSON.stringify(error)
					response.status(500).send error
				else
					logger.debug 'Sending model ' + hash
					response.set 'Content-Type', 'application/octet-stream'
					response.send data
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
		console.log 'Saving model ' + hash
		modelStorage.saveModel hash, content, (error) ->
			if err?
				response.status(500).send 'Error while saving the file'
			else
				response.send 'Saved model'



