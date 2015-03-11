winston = require 'winston'

dpStorage = require '../src/server/sync/dataPacketRamStorage'

module.exports.create = (request, response) ->
	dpStorage.create()
	.then (packet) -> response.status(201).json packet
	.catch -> response.status(500).send 'Packet could not be created'

module.exports.exists = (request, response) ->
	dpStorage.isSaneId request.params.id
	.then ->
		dpStorage.exists request.params.id
		.then (id) -> response.status(200).send id
		.catch (id) -> response.status(404).send id
	.catch -> response.status(400).send 'Invalid data packet id provided'

module.exports.get = (request, response) ->
	dpStorage.isSaneId request.params.id
	.then ->
		dpStorage.get request.params.id
		.then (packet) -> response.status(200).json packet
		.catch (id) -> response.status(404).send id
	.catch -> response.status(400).send 'Invalid data packet id provided'

module.exports.put = (request, response) ->
	dpStorage.isSaneId request.params.id
	.then ->
		dpStorage.put id: request.params.id, data: request.body
		.then (id) -> response.status(200).send id
		.catch (id) -> response.status(404).send id
	.catch -> response.status(400).send 'Invalid data packet id provided'

module.exports.delete = (request, response) ->
	dpStorage.isSaneId request.params.id
	.then ->
		dpStorage.delete request.params.id
		.then -> response.status(204).send()
		.catch (id) -> response.status(404).send id
	.catch -> response.status(400).send 'Invalid data packet id provided'

###
# Use this only for testing!
###
module.exports.clear = () ->
	return dpStorage.clear()
