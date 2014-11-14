##
 # ModelCache
##

# Caches models and allows all Plugins to retrieve cached models from the server

# sends the model to the server if the server hasn't got a file
# with the same file ending and md5 value
submitMeshToServer = (md5hash, fileEnding, data) ->
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
requestMeshFromServer = (md5hashWithEnding, successCallback, failCallback) ->
	splitted = md5hashWithEnding.split('.')
	md5hash = splitted[0]
	fileEnding = splitted[1]
	requestUrl = '/model/get/' + md5hash + '/' + fileEnding
	responseCallback = (data, textStatus, jqXHR) ->
		successCallback(data)

	$.get(requestUrl, "", responseCallback).fail () ->
		failCallback() if failCallback?
module.exports.requestMeshFromServer = requestMeshFromServer