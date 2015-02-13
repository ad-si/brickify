class DataPacketsMock
	constructor: ->
		@calls = 0
		@createCalls = []
		@nextId = false
		@existsCalls = []
		@nextExists = false
		@getCalls = []
		@nextGet = false
		@putCalls = []
		@nextPut = false
		@deleteCalls = []
		@nextDelete = false

	create: =>
		@calls++
		@createCalls.push @nextId
		if @nextId
			return Promise.resolve {id: @nextId, data: {}}
		else
			return Promise.reject()

	exists: (id) =>
		@calls++
		@existsCalls.push id: id, exists: @nextExists
		if @nextExists
			return Promise.resolve id
		else
			return Promise.reject id

	get: (id) =>
		@calls++
		@getCalls.push id: id, get: @nextGet
		if @nextGet
			return Promise.resolve @nextGet
		else
			return Promise.reject id

	put: (packet) =>
		@calls++
		@putCalls.push packet: packet, put: @nextPut
		if @nextPut
			return Promise.resolve packet.id
		else
			return Promise.reject packet.id

	delete: (id) =>
		@calls++
		@deleteCalls.push id: id, delete: @nextDelete
		if @nextDelete
			return Promise.resolve()
		else
			return Promise.reject id

module.exports = DataPacketsMock
