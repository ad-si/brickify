# a simple data packet storage that holds data in memory

packets = {}

module.exports.hasPacket = (id, callback) ->
	if packets[id]?
		callback id, true
	else
		callback id, false

module.exports.getPacket = (id, callback) ->
	callback packets[id]

module.exports.updatePacket = (id, data, callback) ->
	if packets[id]?
		packets[id] = data
		callback true
	else
		callback false

module.exports.createPacket = (id, callback) ->
	packets[id] = {}
	callback packets[id]

