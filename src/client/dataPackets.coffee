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
	if id?
		updatePacket id, data, (result) ->
			if result
				if success?
					success(id)
			else
				if fail?
					fail()
	else
		createPacket (newId) ->
			if newId?
				updatePacket newId, data, (result) ->
					if result
						if success?
							success(newId)
					else
						if fail?
							fail()
			else
				if fail?
					fail()

# creates a packet and returns the id in the callback
createPacket = (callback) ->
	$.get('/datapacket/create')
	.success((json) ->
		callback json.id
	)
	.fail(() ->
		callback null
	)

# uploads an updated packet to the server
updatePacket = (id, packet, callback) ->
	$.ajax '/datapacket/packet/' + id,
		data: {id: id, packet: packet}
		type: 'POST'
		contentType: 'application/json'
		success: () ->
			callback true
		error: () ->
			callback false
