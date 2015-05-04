$ = require 'jquery'
md5 = require('blueimp-md5').md5
meshlib = require 'meshlib'

##
#  ModelCache
#  Caches models and allows all Plugins to retrieve
#  cached models from the server
##

modelCache = {}

sendRequest = (options = {}) ->
	Promise
	.resolve $.ajax options
	.catch (result) -> throw new Error(result.responseText)

saveModelOnServer = (base64Model, hash) ->
	return sendRequest {
		url: '/model/submit/' + hash,
		method: 'POST'
		data: base64Model
		contentType: 'application/octet-stream'
	}


module.exports.store = (model) ->
	hash = ''

	return model
	.getBase64()
	.then (base64Model) ->
		hash = md5 base64Model
		return sendRequest {url: '/model/exists/' + hash}
		.catch (error) ->
			if error.message is 'Model does not exist'
				return saveModelOnServer base64Model, hash
			else
				throw error
	.then ->
		return hash


# Request a model with the given hash
# Will be provided by the cache if present or loaded from the server otherwise
module.exports.request = (hash) ->
	if not modelCache[hash]
		modelCache[hash] = sendRequest {url: '/model/get/' + hash}
		.then (base64Model) ->
			return meshlib
			.Model
			.fromBase64 base64Model

	return modelCache[hash]
