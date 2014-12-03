winston = require 'winston'
log = winston.loggers.get 'log'

dpProvider = require '../src/server/dataPacketProvider'
dpStorage = require '../src/server/dataPacketRamStorage'

dpProvider.init dpStorage

module.exports.getPacket = (request, response) ->
	id = request.params.id
	dpProvider.getPacket id, (packet) ->
		if packet?
			log.debug "Sending packet '#{id}'"
			response.json {packet: packet}
		else
			log.warn "Requested packet '#{id}' does not exist"
			response.status(404).send('')

module.exports.createPacket = (request, response) ->
	dpProvider.createPacket (id) ->
		if id?
			log.debug "Created packet '#{id}'"
			if request.body.packet?
				dpProvider.updatePacket id, request.body.packet, (success) ->
					if success
						response.json {id: id}
					else
						response.status(500).send()
			else
				response.json {id: id}
		else
			log.warn "Error creating packet '#{id}'"
			response.status(500).send()

module.exports.updatePacket = (request, response) ->
	if not (request.body.id? and request.body.packet?)
		response.status(500).send('Not all arguments supplied')
		return

	dpProvider.updatePacket request.body.id, request.body.packet, (success) ->
		if success
			log.debug "Updated packet '#{request.body.id}'"
			response.json {id: request.body.id}
		else
			log.warn "Error updating packet '#{request.body.id}'"
			response.status(500).send()
