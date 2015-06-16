samples = require '../src/server/modelSamples'
storage = require '../src/server/modelStorage'

exists = (key) ->
	return samples.exists key
	.catch -> storage.exists key

module.exports.exists = (request, response) ->
	key = request.params.key

	exists key
	.then -> response.status(200).send key
	.catch -> response.status(404).send key

get = (key) ->
	return samples.get key
	.catch -> storage.get key

module.exports.get = (request, response) ->
	key = request.params.key

	get key
	.then (model) ->
		response.set 'Content-Type', 'application/octet-stream'
		response.send model
	.catch -> response.status(404).send key

module.exports.store = (request, response) ->
	key = request.params.key
	model = request.body

	storage.store key, model
	.then -> response.status(200).send key
	.catch -> response.status(500).send 'Model could not be stored.'
