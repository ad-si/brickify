fs = require 'fs'
mkdirp = require 'mkdirp'
logger = require 'winston'
path = require 'path'
winston = require 'winston'
log = winston.loggers.get('log')

modelCacheDir = ''

module.exports.init = (cacheDir = 'modelCache') ->
	modelCacheDir = cacheDir
	mkdirp cacheDir, (err) ->
		logger.warn 'Unable to create model cache dir: ' + err if err?

module.exports.hasModel = (md5hash, fileEnding, callback) ->
	if not checkHash md5hash, fileEnding
		callback false
		return

	fs.exists buildFileName(md5hash, fileEnding), (exists) ->
		callback(exists)

module.exports.loadModel = (md5hash, fileEnding, callback) ->
	if not checkHash md5hash, fileEnding
		callback 'invalid hash', null
		return

	fs.readFile buildFileName(md5hash, fileEnding), (error, data) ->
		callback(error, data)

module.exports.saveModel = (md5hash, fileEnding, data, callback) ->
	if not checkHash md5hash, fileEnding
		callback 'invalid hash', null
		return

	fs.writeFile buildFileName(md5hash, fileEnding), data, callback

buildFileName = (md5hash, fileEnding) ->
	return path.normalize modelCacheDir + '/' + md5hash + '.' + fileEnding

# checks if the hash and fileEnding are in a valid format
checkHash = (md5hash, fileEnding) ->
	p = /^[0-9a-z]{32}$/
	if p.test md5hash
		if fileEnding == 'optimized' or fileEnding == 'stl'
			return true
	logger.warn "Requested model #{md5hash}.#{fileEnding} is no valid hash"
	return false
