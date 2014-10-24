statedb = require '../src/server/statedb.coffee'
jsondiffpatch = require 'jsondiffpatch'
diffCallbacks = []

exports.getState = (request, response) ->
	stateSession  = request.body.stateSession;
	statedb.retrieveState stateSession, (state) ->
		response.send state

exports.setState = (request, response) ->
	delta = request.body.deltaState
	session = request.body.stateSession

	statedb.retrieveState session, (state) ->
		jsondiffpatch.patch(state,delta)
		#state now contains the current state of both client and server
		oldState = JSON.parse JSON.stringify state

		#call callbacks, let them modify state
		for callback in diffCallbacks
			callback delta, state

		#send diff with our initial state to the client
		diff  = jsondiffpatch.diff oldState, state

		response.json diff

exports.addDiffCallback = (callback) ->
	diffCallbacks.push callback
