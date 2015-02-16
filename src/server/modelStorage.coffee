fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
md5 = require('blueimp-md5').md5

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

loadModel = (hash) ->
	if not checkHash hash
		return Promise.reject 'invalid hash'

	return new Promise((resolve, reject) ->
		fs.readFile buildFileName(hash), (err, data) ->
			if err
				reject err
			else
				resolve data
	)
module.exports.loadModel = loadModel

module.exports.request = (hash) ->
	return loadModel hash

saveModel = (hash, data) ->
	if not checkHash hash
		return Promise.reject 'invalid hash'

	return new Promise((resolve, reject) ->
		fs.writeFile buildFileName(hash), data, (err) ->
			if err
				reject err
			else
				resolve hash
	)
module.exports.saveModel = saveModel

module.exports.store = (optimizedModel) ->
	modelData = optimizedModel.toBase64()
	hash = md5 modelData
	return saveModel hash, modelData

buildFileName = (hash) ->
	return path.normalize modelCacheDir + '/' + hash

# checks if the hash and fileEnding are in a valid format
checkHash = (hash) ->
	p = /^[0-9a-z]{32}$/
	if p.test hash
		return true
	log.warn "Requested model #{hash} is no valid hash"
	return false
