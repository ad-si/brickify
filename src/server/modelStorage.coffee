fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
md5 = require('blueimp-md5').md5

cacheDirectory = 'modelCache/'

module.exports.exists = (hash) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	return new Promise (resolve, reject) ->
		fs.exists cacheDirectory + hash, (exists) ->
			if exists
				resolve hash
			else
				reject hash

module.exports.get = (hash) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	return new Promise (resolve, reject) ->
		fs.readFile cacheDirectory + hash, (error, data) ->
			if error
				reject error
			else
				resolve data

module.exports.store = (hash, model) ->
	unless checkHash hash
		return Promise.reject 'invalid hash'

	if hash isnt md5 model
		return Promise.reject 'wrong hash'

	return new Promise (resolve, reject) ->
		fs.writeFile cacheDirectory + hash, model, (error) ->
			if error
				reject error
			else
				resolve hash

# checks if the hash has the correct format
checkHash = (hash) ->
	p = /^[0-9a-z]{32}$/
	return p.test hash
