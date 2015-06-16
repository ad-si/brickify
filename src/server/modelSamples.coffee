fs = require 'fs'
yaml = require 'js-yaml'
log = require('winston').loggers.get('log')

samplesDirectory = 'modelSamples/'

samples = {}

do loadSamples = ->
	fs
		.readdirSync samplesDirectory
		.filter (file) -> file.endsWith '.yaml'
		.map (file) -> yaml.load fs.readFileSync samplesDirectory + file
		.forEach (sample) -> samples[sample.name] = sample
	log.info 'Sample models loaded'

module.exports.exists = (name) ->
	if samples[name]?
		return Promise.resolve name
	else
		return Promise.reject name

get = (sample) ->
	return new Promise (resolve, reject) ->
		fs.readFile samplesDirectory + sample.name, (error, data) ->
			if error
				reject error
			else
				resolve data

module.exports.get = (name) ->
	if samples[name]?
		return get samples[name]
	else
		return Promise.reject name

module.exports.getSamples = ->
	return Object.keys samples
		.map (key) -> samples[key]
