dpProvider = require '../src/server/dataPacketProvider'
dpStorage = require '../src/server/dataPacketRamStorage'

dpProvider.init dpStorage

module.exports.getPacket = (request, response) ->
	id = request.params.id
	dpProvider.getPacket id, (packet) ->
		if packet?
			response.json {packet: packet}
		else
			response.status(404).send('')

module.exports.createPacket = (request, response) ->
	dpProvider.createPacket (id, packet) ->
		response.json {id: id, packet: packet}

module.exports.updatePacket = (request, response) ->
	if not (request.body.id? and request.body.packet?)
		response.status(500).send('Not all arguments supplied')
		return

	dpProvider.updatePacket request.body.id, request.body.packet, (success) ->
		if success
			response.status(200).send()
		else
			response.status(500).send()
