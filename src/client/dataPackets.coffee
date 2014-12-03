# gets a packet with the specified id
module.exports.get = (id, success, fail) ->
	$.get('/datapacket/packet/' + id)
	.success((json) ->
		success id, json.packet
	)
	.fail(() ->
		fail id, null
	)

# sends a packet to the server. if id is specified, the packet with the same
# id is updated. else, a new id is generated
module.exports.put = (data, id, success, fail) ->
	updatePacket id, data, (result) ->
		if result?
			success? result
		else
			fail?()

# uploads an updated packet to the server
updatePacket = (id = 'undefined', packet, callback) ->
	$.ajax '/datapacket/packet/' + id,
		data: JSON.stringify {id: id, packet: packet}
		type: 'POST'
		contentType: 'application/json'
		success: (json) ->
			callback json.id
		error: () ->
			callback null
