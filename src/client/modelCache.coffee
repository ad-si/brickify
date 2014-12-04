OptimizedModel = require '../common/OptimizedModel'

##
#  ModelCache
#  Caches models and allows all Plugins to retrieve
#  cached models from the server
##

# The cache of loaded optimized models
modelCache = {}

# currently running model queries
modelQueries = {}

exists = (hash) ->
	return Promise.resolve $.get('/model/exists/' + hash)

# sends the model to the server if the server hasn't got a file
# with the same hash value
submitDataToServer = (hash, data) ->
	send = () ->
		Promise.resolve(
			$.ajax(
				'/model/submit/' + hash
				data: data
				type: 'POST'
				contentType: 'application/octet-stream'
			)
		).then(
			() -> console.log 'sent model to the server'
			() -> console.error 'unable to send model to the server'
		)
	return exists(hash).catch(send)

module.exports.store = (optimizedModel) ->
	modelData = optimizedModel.toBase64()
	hash = md5(modelData)
	cache hash, optimizedModel
	return submitDataToServer hash, modelData

# requests a mesh with the given hash from the server
# if it is cached locally, the local reference is returned
requestDataFromServer = (hash) ->
	return Promise.resolve $.get('/model/get/' + hash)

# Request an optimized mesh with the given hash
# The mesh will be provided by the cache if present or loaded from the server
# if available. Otherwise, `fail` will be called
module.exports.request = (hash, success, fail) ->
	if (model = modelCache[hash])?
		success model
	else if (query = modelQueries[hash])?
		query.successCallbacks.push success
		query.failCallbacks.push fail
	else
		query = {
			hash: hash
			successCallbacks: [success]
			failCallbacks: [fail]
		}
		modelQueries[hash] = query
		requestDataFromServer(hash).then(
			requestOptimizedModelSuccess query
			requestOptimizedModelFail query
		)

requestOptimizedModelSuccess = (query) -> (data) ->
	model = new OptimizedModel()
	model.fromBase64 data
	hash = md5(data)
	cache hash, model
	successCallback model for successCallback in query.successCallbacks
	deleteQuery query

requestOptimizedModelFail = (query) -> () ->
	failCallback() for failCallback in query.failCallbacks
	deleteQuery query

deleteQuery = (query) ->
	delete modelQueries[query.hash]

cache = (hash, model) ->
	modelCache[hash] = model
