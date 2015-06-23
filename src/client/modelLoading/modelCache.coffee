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

exists = (identifier) ->
	return Promise.resolve(
		$.ajax '/model/' + identifier,
			type: 'HEAD'
	).catch (jqXHR) -> throw new Error jqXHR.statusText
module.exports.exists = exists

# sends the model to the server if the server hasn't got a model
# with the same identifier
submitDataToServer = (identifier, data) ->
	send = ->
		prom = Promise.resolve(
			$.ajax '/model/' + identifier,
				data: data
				type: 'PUT'
				contentType: 'application/octet-stream'
		).catch (jqXHR) -> throw new Error jqXHR.statusText
		prom.then(
			-> log.debug 'Sent model to the server'
			-> log.error 'Unable to send model to the server'
		)
		return prom
	return exists(identifier).catch(send)

module.exports.store = (model) ->
	return model
		.getBase64()
		.then (base64Model) ->
			identifier = md5 base64Model
			modelCache[identifier] = Promise.resolve model
			return submitDataToServer identifier, base64Model
				.then ->
					return identifier

# requests a mesh with the given identifier from the server
requestDataFromServer = (identifier) ->
	return Promise.resolve $.get '/model/' + identifier
		.catch (jqXHR) -> throw new Error jqXHR.statusText

buildModelPromise = (identifier) ->
	return requestDataFromServer identifier
		.then (base64Model) ->
			return meshlib.Model
				.fromBase64 base64Model
				.buildFacesFromFaceVertexMesh()


# Request an optimized mesh with the given identifier
# The mesh will be provided by the cache if present or loaded from the server
# if available.
module.exports.request = (identifier) ->
	return modelCache[identifier] ?= buildModelPromise(identifier)
