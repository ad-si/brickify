class ModelProviderMock
	constructor: ->
		@calls = 0
		@storeCalls = []
		@nextStore = false
		@requestCalls = []
		@nextRequest = false

	store: (model) =>
		@calls++
		@storeCalls.push model: model, store: @nextStore
		if @nextStore
			return Promise.resolve()
		else
			return Promise.reject()

	request: (identifier) =>
		@calls++
		@requestCalls.push identifier: identifier, request: @nextRequest
		if @nextRequest
			return Promise.resolve @nextRequest
		else
			return Promise.reject()

module.exports = ModelProviderMock
