OptimizedModel = require '../common/OptimizedModel'

##
 # ModelCache
##

# Caches models and allows all Plugins to retrieve cached models from the server

#the cache for raw data of any kind
modelCache = []

#the cache for optimized model instances
optimizedModelCache = []

# sends the model to the server if the server hasn't got a file
# with the same file ending and md5 value
# model will be cached locally
submitMeshToServer = (md5hash, fileEnding, data) ->
	addModelToCache md5hash + '.' + fileEnding, data

	$.get('/model/exists/' + md5hash + '/' + fileEnding).fail () ->
		#server hasn't got the model, send it
		$.ajax '/model/submit/' + md5hash + '/' + fileEnding,
			data: data
			type: 'POST'
			contentType: 'application/octet-stream'
			success: () ->
				console.log 'sent model to the server'
			error: () ->
				console.log 'unable to send model to the server'
module.exports.submitMeshToServer = submitMeshToServer

# Same as submit mesh to server, but the optimized model instance will be cached
submitOptimizedMeshToServer = (md5hash, fileEnding, optimizedModelInstance) ->
	addOptimizedInstance md5hash + '.' + fileEnding, optimizedModelInstance
	serialized = optimizedModelInstance.toBase64()

	submitMeshToServer md5hash,fileEnding, optimizedModelInstance
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
	modelInstance = getOptimizedInstance md5hashWithEnding
	if modelInstance?
		success modelInstance

	successCb = (data) ->
		modelInstance = new OptimizedModel()
		modelInstance.fromBase64 data
		addOptimizedInstance md5hashWithEnding, modelInstance
		success modelInstance

	requestMeshFromServer md5hashWithEnding, successCb, fail
module.exports.requestOptimizedMeshFromServer = requestOptimizedMeshFromServer

addModelToCache = (md5hashWithEnding, data) ->
	for m in modelCache
		if m.hash == md5hashWithEnding
			return
	modelCache.push {hash: md5hashWithEnding, data: data}

getModelFromCache = (md5hashWithEnding) ->
	for m in modelCache
		if m.hash == md5hashWithEnding
			return m.data
	return null

addOptimizedInstance = (md5HashWithEnding, instance) ->
	for m in optimizedModelCache
		if m.hash == md5HashWithEnding
			return
	optimizedModelCache.push {hash: md5HashWithEnding, data: instance}

getOptimizedInstance = (md5HashWithEnding) ->
	for m in optimizedModelCache
		if m.hash == md5HashWithEnding
			return m.data
	return null
