dpStorage = null

module.exports.init = (packetStorage) ->
	dpStorage = packetStorage
	if dpStorage.init?
		dpStorage.init

module.exports.getPacket = (id, callback) ->
	if not isSaneId id
		callback null

	dpStorage.getPacket id, callback

module.exports.createPacket = (callback) ->
	# create random Ids until there is a id that is not assigned to a packet
	check = (id, idAlreadyExists = true) ->
		if idAlreadyExists
			newId = createId()
			dpStorage.hasPacket newId, check
		else
			dpStorage.createPacket id, (success) ->
				if (success)
					callback id
				else
					callback null

	check()

module.exports.updatePacket = (id, data, callback) ->
	if not isSaneId id
		callback false

	dpStorage.updatePacket id, data, callback

createId = () ->
	chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
	len = 8
	result = ''
	for i in [0..len - 1]
		index = Math.floor((Math.random() * chars.length))
		c = chars[index]
		result += c
	return result

isSaneId = (id) ->
	p = /^([0-9]|[a-z]|[A-Z]){8}$/
	return p.test id
