fs = require 'fs'
fsp = require 'fs-promise'
mkdirp = require 'mkdirp'
path = require 'path'
md5 = require('blueimp-md5').md5
log = require('winston').loggers.get 'log'

cacheDirectory = 'modelCache/'

# create cache directory on require (read: on server startup)
do createCacheDirectory = ->
	mkdirp cacheDirectory, (error) ->
		log.warn 'Unable to create cache directory: ' + error if error?

# API

exists = (hash) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	return new Promise (resolve, reject) ->
		fs.exists cacheDirectory + hash, (exists) ->
			if exists
				resolve hash
			else
				reject hash

get = (hash) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	return fsp.readFile cacheDirectory + hash

store = (hash, model) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	if hash isnt md5 model
		return Promise.reject 'wrong hash'

	return fsp.writeFile cacheDirectory + hash, model
		.then -> return hash

# checks if the hash has the correct format
checkHash = (hash) ->
	p = /^[0-9a-z]{32}$/
	return p.test hash

module.exports = {
	exists
	get
	store
}
