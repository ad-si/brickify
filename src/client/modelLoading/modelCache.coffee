$ = require 'jquery'
md5 = require('blueimp-md5').md5
meshlib = require 'meshlib'
log = require 'loglevel'

##
#  ModelCache
#  Caches models and allows all Plugins to retrieve
#  cached models from the server
##

# The cache of optimized model promises
modelCache = {}

exists = (hash) ->
	return Promise.resolve $.get '/model/exists/' + hash
		.catch (jqXHR) -> throw new Error jqXHR.statusText
module.exports.exists = exists

# sends the model to the server if the server hasn't got a file
# with the same hash value
submitDataToServer = (hash, data) ->
	send = ->
		prom = Promise.resolve(
			$.ajax '/model/submit/' + hash,
				data: data
				type: 'POST'
				contentType: 'application/octet-stream'
		).catch (jqXHR) -> throw new Error jqXHR.statusText
		prom.then(
			-> log.debug 'Sent model to the server'
			-> log.error 'Unable to send model to the server'
		)
		return prom
	return exists(hash).catch(send)

module.exports.store = (model) ->
	return model
		.getBase64()
		.then (base64Model) ->
			hash = md5 base64Model
			modelCache[hash] = Promise.resolve model
			return submitDataToServer(hash, base64Model).then -> hash

# requests a mesh with the given hash from the server
requestDataFromServer = (hash) ->
	return Promise.resolve $.get '/model/get/' + hash
		.catch (jqXHR) -> throw new Error jqXHR.statusText

buildModelPromise = (hash) ->
	return requestDataFromServer(hash)
		.then (base64Model) ->
			return meshlib.Model
				.fromBase64 base64Model
				.buildFacesFromFaceVertexMesh()


# Request an optimized mesh with the given hash
# The mesh will be provided by the cache if present or loaded from the server
# if available.
module.exports.request = (hash) ->
	return modelCache[hash] ?= buildModelPromise(hash)
