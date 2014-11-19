modelStorage = require '../src/server/modelStorage'
md5Calc = require 'MD5'
logger = require 'winston'

module.exports.modelExists = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	modelStorage.hasModel md5, fileEnding, (hasModel) ->
		if hasModel
			logger.debug 'Model ' + md5 + '.' + fileEnding + ' exists'
			response.status(200).send('Model exists')
		else
			logger.debug 'Model ' + md5 + '.' + fileEnding + ' does not exist'
			response.status(404).send('Model does not exist')

module.exports.getModel = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	modelStorage.hasModel md5, fileEnding, (hasModel) ->
		if hasModel
			modelStorage.loadModel md5, fileEnding, (error, data) ->
				if error?
					logger.warn 'Unable to load model ' +
						md5 + '.' + fileEnding + ': ' + JSON.stringify(error)
					response.status(500).send error
				else
					logger.debug 'Sending model ' + md5 + '.' + fileEnding
					response.set 'Content-Type', 'application/octet-stream'
					response.send data
		else
			logger.warn 'Unable to load model ' +
				md5 + '.' + fileEnding + ': model not found'
			response.status(404).send 'Model not found'

module.exports.saveModel = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	content = request.body
	calculatedMd5 = md5Calc content

	if not md5 == calculatedMd5
		response.status(500).send 'Calculated MD5 value does not match'
	else
		console.log 'Saving model ' + md5
		modelStorage.saveModel calculatedMd5, fileEnding, content, (error) ->
			if err?
				response.status(500).send 'Error while saving the file'
			else
				response.send 'Saved model'



