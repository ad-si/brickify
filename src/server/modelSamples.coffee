fs = require 'fs'
yaml = require 'js-yaml'
log = require('winston').loggers.get 'log'

samplesDirectory = 'modelSamples/'

samples = {}

# load samples on require (read: on server startup)
do loadSamples = ->
	fs
		.readdirSync samplesDirectory
		.filter (file) -> file.endsWith '.yaml'
		.map (file) -> yaml.load fs.readFileSync samplesDirectory + file
		.forEach (sample) -> samples[sample.name] = sample
	log.info 'Sample models loaded'

# API

exists = (name) ->
	if samples[name]?
		return Promise.resolve name
	else
		return Promise.reject name

get = (name) ->
	if samples[name]?
		return new Promise (resolve, reject) ->
			fs.readFile samplesDirectory + name, (error, data) ->
				if error
					reject error
				else
					resolve data
	else
		return Promise.reject name

getSamples = ->
	return Object.keys samples
		.map (key) -> samples[key]

module.exports = {
	exists
	get
	getSamples
}
