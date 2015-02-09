###
# The combined client-side local data packet provider and cache.
#
# @module clientDataPackets
###

cache = require './dataPacketsCache'
proxy = require './dataPacketsProxy'

module.exports.create = ->
	return proxy.create().then cache.create

module.exports.exists = (id) ->
	return cache.exists(id).catch proxy.exists

module.exports.get = (id) ->
	return cache.get(id).catch(-> proxy.get(id).then cache.cache)

module.exports.put = (packet) ->
	return cache.put(packet).then -> proxy.put packet

module.exports.delete = (id) ->
	# The packet might not be in the cache - but still needs to be deleted
	# from the server, therefore call proxy.delete in any case and use its result
	return cache.delete(id).then(
		-> proxy.delete id
		-> proxy.delete id
	)
