modelStorage = require '../src/server/modelStorage'
md5Calc = require 'MD5'

module.exports.modelExists = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	modelStorage.hasModel md5, fileEnding, (hasModel) ->
		if hasModel
			response.status(200).send('Model exists')
		else
			response.status(404).send('Model does not exist')

module.exports.getModel = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	modelStorage.hasModel md5, fileEnding, (hasModel) ->
		if hasModel
			modelStorage.loadModel md5, fileEnding, (error, data) ->
				if error?
					response.status(500).send error
				else
					response.set 'Content-Type', 'application/octet-stream'
					response.send data

module.exports.saveModel = (request, response) ->
	md5 = request.params.md5
	fileEnding = request.params.extension
	content = request.body
	calculatedMd5 = md5Calc content

	if not md5 == calculatedMd5
		response.status(500).send "Calculated MD5 value does not match"
	else
		console.log 'Saving model ' + md5
		modelStorage.saveModel calculatedMd5, fileEnding, content, (error) ->
			if err?
				response.status(500).send "Error while saving the file"
			else
				response.send "Saved model"



