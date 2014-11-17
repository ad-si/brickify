##
 # ModelCache
##

# Caches models and allows all Plugins to retrieve cached models from the server

modelCache = []

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

# requests a mesh with the given md5hash.ending from the server
# if it is cached locally, the local reference is returned
requestMeshFromServer = (md5hashWithEnding, successCallback, failCallback) ->
	model = getModelFromCache md5hashWithEnding
	if model?
		successCallback(model)
		return

	splitted = md5hashWithEnding.split('.')
	md5hash = splitted[0]
	fileEnding = splitted[1]
	requestUrl = '/model/get/' + md5hash + '/' + fileEnding
	responseCallback = (data, textStatus, jqXHR) ->
		addModelToCache md5hashWithEnding, data
		successCallback(data)

	$.get(requestUrl, '', responseCallback).fail () ->
		failCallback() if failCallback?
module.exports.requestMeshFromServer = requestMeshFromServer

addModelToCache = (md5hashWithEnding, data) ->
	for m in modelCache
		if (m.hash == md5hashWithEnding)
			return
	modelCache.push {hash: md5hashWithEnding, data: data}

getModelFromCache = (md5hashWithEnding) ->
	for m in modelCache
		if (m.hash == md5hashWithEnding)
			return m.data
	return null
