fs = require 'fs'
mkdirp = require 'mkdirp'
logger = require 'winston'
path = require 'path'

modelCacheDir = ''

module.exports.init = (cacheDir = 'modelCache') ->
	modelCacheDir = cacheDir
	mkdirp cacheDir, (err) ->
		logger.warn 'Unable to create model cache dir: ' + err if err?

module.exports.hasModel = (md5hash, fileEnding, callback) ->
	fs.exists buildFileName(md5hash, fileEnding), (exists) ->
		callback(exists)

module.exports.loadModel = (md5hash, fileEnding, callback) ->
	fs.readFile buildFileName(md5hash, fileEnding), (error, data) ->
		callback(error, data)

module.exports.saveModel = (md5hash, fileEnding, data, callback) ->
	fs.writeFile buildFileName(md5hash, fileEnding), data, callback

buildFileName = (md5hash, fileEnding) ->
	return path.normalize modelCacheDir + '/' + md5hash + '.' + fileEnding
