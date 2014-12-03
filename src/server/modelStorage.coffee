fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'

winston = require 'winston'
log = winston.loggers.get('log')

modelCacheDir = ''

module.exports.init = (cacheDir = 'modelCache') ->
	modelCacheDir = cacheDir
	mkdirp cacheDir, (err) ->
		log.warn 'Unable to create model cache dir: ' + err if err?

module.exports.hasModel = (hash, callback) ->
	if not checkHash hash
		callback false
		return

	fs.exists buildFileName(hash), (exists) ->
		callback(exists)

module.exports.loadModel = (hash, callback) ->
	if not checkHash hash
		callback 'invalid hash', null
		return

	fs.readFile buildFileName(hash), (error, data) ->
		callback(error, data)

module.exports.saveModel = (hash, data, callback) ->
	if not checkHash hash
		callback 'invalid hash', null
		return

	fs.writeFile buildFileName(hash), data, callback

buildFileName = (hash) ->
	return path.normalize modelCacheDir + '/' + hash

# checks if the hash and fileEnding are in a valid format
checkHash = (hash) ->
	p = /^[0-9a-z]{32}$/
	if p.test hash
		return true
	log.warn "Requested model #{hash} is no valid hash"
	return false
