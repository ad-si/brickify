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
	return Promise.resolve $.ajax '/datapacket', type: 'POST'
		.catch sanitizeJqXHRError

module.exports.exists = (id) ->
	return Promise.resolve $.ajax '/datapacket/' + id, type: 'HEAD'
		.catch sanitizeJqXHRError

module.exports.get = (id) ->
	return Promise.resolve $.ajax '/datapacket/' + id, type: 'GET'
		.catch sanitizeJqXHRError

module.exports.put = (packet) ->
	return Promise.resolve(
		$.ajax '/datapacket/' + packet.id, type: 'PUT',
			contentType: 'application/json'
			data: JSON.stringify packet.data
	).catch sanitizeJqXHRError

module.exports.delete = (id) ->
	return Promise.resolve $.ajax '/datapacket/' + id, type: 'DELETE'
		.catch sanitizeJqXHRError
