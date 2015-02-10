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
	return proxy.put(packet).then((proxyResult) ->
		cache.cache(packet).then(->
			return proxyResult
	))

module.exports.delete = (id) ->
	return proxy.delete(id).then((proxyResult) ->
		cache.ensureDelete(id).then(->
			return proxyResult
	))

module.exports.clear = ->
	cache.clear()
