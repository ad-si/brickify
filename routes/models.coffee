samples = require '../src/server/modelSamples'
storage = require '../src/server/modelStorage'

exists = (identifier) ->
	return samples.exists identifier
	.catch -> storage.exists identifier

module.exports.exists = (request, response) ->
	identifier = request.params.identifier

	exists identifier
	.then -> response.status(200).send identifier
	.catch -> response.status(404).send identifier

get = (identifier) ->
	return samples.get identifier
	.catch -> storage.get identifier

module.exports.get = (request, response) ->
	identifier = request.params.identifier

	get identifier
	.then (model) ->
		response.set 'Content-Type', 'application/octet-stream'
		response.send model
	.catch -> response.status(404).send identifier

module.exports.store = (request, response) ->
	identifier = request.params.identifier
	model = request.body

	storage.store identifier, model
	.then -> response.status(200).send identifier
	.catch -> response.status(500).send 'Model could not be stored.'
