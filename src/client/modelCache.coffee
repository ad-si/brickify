OptimizedModel = require '../common/OptimizedModel'

##
 # ModelCache
##

# Caches models and allows all Plugins to retrieve cached models from the server

# the cache for raw data of any kind
modelCache = {}

# the cache for optimized model instances
optimizedModelCache = {}

# currently running model queries
currentOptimizedModelQueries = {}

# sends the model to the server if the server hasn't got a file
# with the same file ending and md5 value
# model will be cached locally
submitMeshToServer = (hash, fileEnding, data) ->
	addModelToCache hash + '.' + fileEnding, data

	$.get('/model/exists/' + hash + '/' + fileEnding).fail () ->
		#server hasn't got the model, send it
		$.ajax '/model/submit/' + hash + '/' + fileEnding,
			data: data
			type: 'POST'
			contentType: 'application/octet-stream'
			success: () ->
				console.log 'sent model to the server'
			error: () ->
				console.error 'unable to send model to the server'
module.exports.submitMeshToServer = submitMeshToServer

# Same as submit mesh to server, but the optimized model instance will be cached
submitOptimizedMeshToServer = (hash, fileEnding, optimizedModelInstance) ->
	addOptimizedInstance hash + '.' + fileEnding, optimizedModelInstance
	serialized = optimizedModelInstance.toBase64()

	submitMeshToServer hash, fileEnding, optimizedModelInstance
module.exports.submitOptimizedMeshToServer = submitOptimizedMeshToServer

# requests a mesh with the given md5hash.ending from the server
# if it is cached locally, the local reference is returned
# if the mesh ends with .optimized, the instance (and not the raw data)
# of the optimized model is returned
requestMeshFromServer = (md5hashWithEnding, successCallback, failCallback) ->
	model = getModelFromCache md5hashWithEnding
	if model?
		successCallback model
		return

	splitted = md5hashWithEnding.split('.')
	md5hash = splitted[0]
	fileEnding = splitted[1]
	requestUrl = '/model/get/' + md5hash + '/' + fileEnding
	responseCallback = (data, textStatus, jqXHR) ->
			addModelToCache md5hashWithEnding, data
			successCallback data

	$.get(requestUrl, '', responseCallback).fail () ->
		failCallback() if failCallback?
module.exports.requestMeshFromServer = requestMeshFromServer

# Same as requestMeshFromServer, but returns cached optimizedModel instance if
# it exists
requestOptimizedMeshFromServer = (md5hashWithEnding, success, fail) ->
	hash = md5hashWithEnding.split('.')[0]
	requestOptimizedMesh hash, success, fail
module.exports.requestOptimizedMeshFromServer = requestOptimizedMeshFromServer

# NEWONE
requestOptimizedMesh = (hash, success, fail) ->
	if (model = modelCache[hash])?
		success model
	else if (query = currentOptimizedModelQueries[hash])?
		query.successCallbacks.push success
		query.failCallbacks.push fail
	else
		query = {
			hash: hash
			successCallbacks: [success]
			failCallbacks: [fail]
		}
		currentOptimizedModelQueries[hash] = query
		requestMeshFromServer(
			hash+'.optimized'
			requestOptimizedMeshSuccess query
			requestOptimizedMeshFail query
		)

requestOptimizedMeshSuccess = (query) -> (data) ->
	model = new OptimizedModel()
	model.fromBase64 data
	addOptimizedInstance query.hash, model
	success model for success in query.successCallbacks
	deleteQuery query

requestOptimizedMeshFail = (query) -> () ->
	fail() for fail in query.failCallbacks
	deleteQuery query

addModelToCache = (hash, data) ->
	modelCache[hash] ?= {hash: hash, data: data}

getModelFromCache = (hash) ->
	modelCache[hash]?.data

addOptimizedInstance = (hash, instance) ->
	optimizedModelCache[hash] ?=
		{hash: hash, data: instance}

getOptimizedInstance = (hash) ->
	optimizedModelCache[hash]?.data

getQueryForOptimizedModel = (hash) ->
	currentOptimizedModelQueries[hash] ?= {
		hash: hash
		successCallbacks: []
		failCallbacks: []
	}

deleteQuery = (query) ->
	delete currentOptimizedModelQueries[query.hash]
