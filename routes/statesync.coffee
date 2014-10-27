jsondiffpatch = require 'jsondiffpatch'
diffCallbacks = []

exports.getState = (request, response) ->
	state = getInitializedState request
	response.json state

exports.setState = (request, response) ->
	delta = request.body.deltaState
	console.log 'updated delta: ' + JSON.stringify(delta)

	state = getInitializedState request

	jsondiffpatch.patch(state,delta)
	console.log 'updated state:' + JSON.stringify(state)
	#state now contains the current state of both client and server

	oldState = JSON.parse JSON.stringify state

	#call callbacks, let them modify state
	for callback in diffCallbacks
		callback delta, state

	#send diff with our initial state to the client
	diff  = jsondiffpatch.diff oldState, state

	console.log 'Sending delta to client: ' + JSON.stringify(diff)
	response.json diff

exports.resetState = (request, response) ->
	request.session.state = {empty: true}
	response.json request.session.state

exports.addUpdateCallback = (callback) ->
	diffCallbacks.push callback

getInitializedState = (request) ->
	state = request.session.state
	stateInitialized = request.session.stateIsInitialized

	if stateInitialized == true
		return state
	else
		request.session.state = {empty: true}
		request.session.stateIsInitialized = true
		return request.session.state