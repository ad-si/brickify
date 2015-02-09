###
# A simple data packet storage that holds data in memory
#
# @module dataPacketRamStorage
###

idGenerator = require './idGenerator'

packets = {}

module.exports.create = ->
	id = idGenerator.generate (id) -> !packets[id]?
	packets[id] = {
		id: id
		data: {}
	}
	return Promise.resolve packets[id]

module.exports.isSaneId = (id) ->
	if idGenerator.check id
		return Promise.resolve id
	else
		return Promise.reject id

module.exports.exists = (id) ->
	if packets[id]?
		return Promise.resolve id
	else
		return Promise.reject id

module.exports.get = (id) ->
	if packets[id]?
		return Promise.resolve packets[id]
	else
		return Promise.reject id

module.exports.put = (packet) ->
	if packets[packet.id]?
		packets[packet.id].data = packet.data
		return Promise.resolve packet.id
	else
		return Promise.reject packet.id

#TODO: module.exports.patch

module.exports.delete = (id) ->
	if packets[id]?
		delete packets[id]
		return Promise.resolve()
	else
		return Promise.reject id

module.exports.clear = ->
	packets = {}
	return Promise.resolve()
