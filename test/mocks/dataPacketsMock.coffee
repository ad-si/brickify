class DataPacketsMock
	constructor: ->
		@calls = 0
		@createCalls = []
		@nextIds = []
		@existsCalls = []
		@nextExists = []
		@getCalls = []
		@nextGets = []
		@putCalls = []
		@nextPuts = []
		@deleteCalls = []
		@nextDeletes = []

	create: =>
		@calls++
		nextId = @nextIds.shift()
		@createCalls.push nextId
		if nextId
			return Promise.resolve {id: nextId, data: {}}
		else
			return Promise.reject()

	exists: (id) =>
		@calls++
		nextExist = @nextExists.shift()
		@existsCalls.push id: id, exists: nextExist
		if nextExist
			return Promise.resolve id
		else
			return Promise.reject id

	get: (id) =>
		@calls++
		nextGet = @nextGets.shift()
		@getCalls.push id: id, get: nextGet
		if nextGet
			return Promise.resolve nextGet
		else
			return Promise.reject id

	put: (packet) =>
		@calls++
		p = JSON.parse JSON.stringify packet
		nextPut = @nextPuts.shift()
		@putCalls.push packet: p, put: nextPut
		if nextPut
			return Promise.resolve p.id
		else
			return Promise.reject p.id

	delete: (id) =>
		@calls++
		nextDelete = @nextDeletes.shift()
		@deleteCalls.push id: id, delete: nextDelete
		if nextDelete
			return Promise.resolve()
		else
			return Promise.reject id

module.exports = DataPacketsMock
