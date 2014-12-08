md5 = require('blueimp-md5').md5
OptimizedModel = require '../common/OptimizedModel'

##
#  ModelCache
#  Caches models and allows all Plugins to retrieve
#  cached models from the server
##

# The cache of optimized model promises
modelCache = {}

exists = (hash) ->
	return Promise.resolve $.get('/model/exists/' + hash)

# sends the model to the server if the server hasn't got a file
# with the same hash value
submitDataToServer = (hash, data) ->
	send = () ->
		prom = Promise.resolve(
			$.ajax(
				'/model/submit/' + hash
				data: data
				type: 'POST'
				contentType: 'application/octet-stream'
			)
		)
		prom.then(
			() -> console.log 'sent model to the server'
			() -> console.error 'unable to send model to the server'
		)
		return prom
	return exists(hash).catch(send)

module.exports.store = (optimizedModel) ->
	modelData = optimizedModel.toBase64()
	hash = md5(modelData)
	modelCache[hash] = Promise.resolve optimizedModel
	return submitDataToServer hash, modelData

# requests a mesh with the given hash from the server
requestDataFromServer = (hash) ->
	return Promise.resolve $.get('/model/get/' + hash)

buildModelPromise = (hash) ->
	return requestDataFromServer(hash).then((data) ->
		model = new OptimizedModel()
		model.fromBase64 data
		return model
	)

# Request an optimized mesh with the given hash
# The mesh will be provided by the cache if present or loaded from the server
# if available.
module.exports.request = (hash) ->
	return modelCache[hash] ?= buildModelPromise(hash)
