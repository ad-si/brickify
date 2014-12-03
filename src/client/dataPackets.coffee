# creates a packet and returns the id in the callback
module.exports.createPacket = (callback) ->
	$.get('/datapacket/create')
	.success((json) ->
		callback json.id
	)
	.fail(() ->
		callback null
	)

# gets a packet with the specified id
module.exports.getPacket = (id, callback) ->
	$.get('/datapacket/packet/' + id)
	.success((json) ->
		callback id, json.packet
	)
	.fail(() ->
		callback id, null
	)

# uploads an updated packet to the server
module.exports.updatePacket = (id, packet, callback) ->
	$.ajax '/datapacket/packet' + id,
		data: {id: id, packet: packet}
		type: 'POST'
		contentType: 'application/json'
		success: () ->
			callback true
		error: () ->
			callback false
