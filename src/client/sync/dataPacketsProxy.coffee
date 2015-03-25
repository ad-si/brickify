###
# The client's data packet proxy that interacts with the server
#
# @module clientDataPacketsProxy
###
$ = require 'jquery'

module.exports.create = ->
	return Promise.resolve $.ajax '/datapacket/create', type: 'GET'
		.catch (jqXHR) -> throw new Error jqXHR.statusText

module.exports.exists = (id) ->
	return Promise.resolve $.ajax '/datapacket/exists/' + id, type: 'GET'
		.catch (jqXHR) -> throw new Error jqXHR.statusText

module.exports.get = (id) ->
	return Promise.resolve $.ajax '/datapacket/get/' + id, type: 'GET'
		.catch (jqXHR) -> throw new Error jqXHR.statusText

module.exports.put = (packet) ->
	return Promise.resolve(
		$.ajax '/datapacket/put/' + packet.id, type: 'PUT',
			contentType: 'application/json'
			data: JSON.stringify packet.data
	).catch (jqXHR) -> throw new Error jqXHR.statusText

module.exports.delete = (id) ->
	return Promise.resolve $.ajax '/datapacket/delete/' + id, type: 'DELETE'
		.catch (jqXHR) -> throw new Error jqXHR.statusText
