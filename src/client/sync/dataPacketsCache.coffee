###
# The client's data packet cache
#
# @module clientDataPacketsCache
###

# A map of promises that resolve to the respective packet or reject with its id
packets = {}

module.exports.cache = (packet) ->
	return Promise.resolve packets[packet.id] = packet
cache = module.exports.cache

module.exports.create = (packet) ->
	return Promise.resolve packets[packet.id] = packet

module.exports.exists = (id) ->
	packets[id] ?= Promise.reject id
	return packets[id].then -> id
exists = module.exports.exists

module.exports.get = (id) ->
	return packets[id] ?= Promise.reject id

module.exports.put = (packet) ->
	return exists(packet.id).then(-> cache packet).then Promise.resolve packet.id

#TODO: module.exports.patch

module.exports.delete = (id) ->
	if packets[id]?
		delete packets[id]
		return Promise.resolve()
	else
		return Promise.reject id
