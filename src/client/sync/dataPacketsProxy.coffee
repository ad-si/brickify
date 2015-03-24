###
# The client's data packet proxy that interacts with the server
#
# @module clientDataPacketsProxy
###
$ = require 'jquery'

module.exports.create = ->
	return Promise.resolve $.ajax '/datapacket/create', type: 'GET'

module.exports.exists = (id) ->
	return Promise.resolve $.ajax '/datapacket/exists/' + id, type: 'GET'

module.exports.get = (id) ->
	return Promise.resolve $.ajax '/datapacket/get/' + id, type: 'GET'

module.exports.put = (packet) ->
	return Promise.resolve(
		$.ajax '/datapacket/put/' + packet.id, type: 'PUT',
			contentType: 'application/json'
			data: JSON.stringify packet.data
	)

module.exports.delete = (id) ->
	return Promise.resolve $.ajax '/datapacket/delete/' + id, type: 'DELETE'
