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


module.exports.store = (model) ->
	hash = ''
	base64Model = ''

	return model
	.getBase64()
	.then (base64Model) ->
		hash = md5 base64Model
		modelCache[hash] = model

		return sendRequest {url: '/model/exists/' + hash}
			.catch (error) ->
				if error.message is 'Model does not exist'

					return sendRequest {
						url: '/model/submit/' + hash,
						method: 'POST'
						data: base64Model
						contentType: 'application/octet-stream'
					}
				else
					throw error
	.then ->
		return hash

# Request a model with the given hash
# Will be provided by the cache if present or loaded from the server otherwise
module.exports.request = (hash) ->
	if modelCache[hash]
		return Promise.resolve modelCache[hash]
	else
		return sendRequest {url: '/model/get/' + hash}
		.then (base64Model) ->
			return meshlib
			.Model
			.fromBase64 base64Model
			#.done (modelPromise) -> modelPromise
