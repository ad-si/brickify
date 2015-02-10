###
# The client's data packet cache
#
# @module clientDataPacketsCache
###

# A map of promises that resolve to the respective packet or reject with its id
packets = {}

# cache is the big brother of put: it will always store the packet and resolve
module.exports.cache = (packet) ->
	return packets[packet.id] = Promise.resolve packet
cache = module.exports.cache

# ensureDelete is the big brother of delete: it will delete the packet if
# present and always resolve
module.exports.ensureDelete = (id) ->
	delete packets[id]
	return Promise.resolve()
ensureDelete = module.exports.ensureDelete

module.exports.create = (packet) ->
	return cache packet

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
		return ensureDelete id
	else
		return Promise.reject id

module.exports.clear = ->
	packets = {}
	return Promise.resolve()
