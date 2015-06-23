###
# The client's data packet proxy that interacts with the server
#
# @module clientDataPacketsProxy
###
$ = require 'jquery'

sanitizeJqXHRError = (jqXHR) ->
	return Promise.reject {
		status: jqXHR.status
		statusText: jqXHR.statusText
		responseText: jqXHR.responseText
	}

module.exports.create = ->
	return Promise.resolve $.ajax '/datapacket/create', type: 'GET'
		.catch sanitizeJqXHRError

module.exports.exists = (id) ->
	return Promise.resolve $.ajax '/datapacket/exists/' + id, type: 'GET'
		.catch sanitizeJqXHRError

module.exports.get = (id) ->
	return Promise.resolve $.ajax '/datapacket/get/' + id, type: 'GET'
		.catch sanitizeJqXHRError

module.exports.put = (packet) ->
	return Promise.resolve(
		$.ajax '/datapacket/put/' + packet.id, type: 'PUT',
			contentType: 'application/json'
			data: JSON.stringify packet.data
	).catch sanitizeJqXHRError

module.exports.delete = (id) ->
	return Promise.resolve $.ajax '/datapacket/delete/' + id, type: 'DELETE'
		.catch sanitizeJqXHRError
