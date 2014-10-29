jsondiffpatch = require 'jsondiffpatch'

state = {}
oldState = {}

globalConfigInstance = null
stateUpdateCallbacks = []

exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig
	$.get "/statesync/get", {}, (data, textStatus, jqXHR) ->
		state = data
		oldState = JSON.parse JSON.stringify state
		handleUpdatedState({}, state)

sync = (force = false) ->
	delta = jsondiffpatch.diff oldState, state

	if not force
		if not delta?
			return

	# deep copy
	oldState = JSON.parse JSON.stringify state

	console.log 'Sending delta: ' +
		JSON.stringify({deltaState: delta}) +
		' to server (state: ' +
		JSON.stringify(state) + ')'

	$.ajax '/statesync/set',
		type: 'POST'
		data: JSON.stringify({deltaState: delta})
		# what jquery expects as an answer
		dataType: 'json'
		# what is sent in the post request as a header
		contentType: 'application/json; charset=utf-8'
		# check whether client modified its local state
		# since the post request was sent
		success: (data, textStatus, jqXHR) ->

			clientDelta = jsondiffpatch.diff oldState, state
			if clientDelta?
				console.log 'The client modified its state' +
					'while the server worked, this should not happen!'

			#patch state with server changes
			delta = data
			jsondiffpatch.patch state, delta

			#deep copy current state
			oldState = JSON.parse JSON.stringify state

			handleUpdatedState(delta, state)

exports.sync = sync

exports.addUpdateCallback = (callback) ->
	stateUpdateCallbacks.push callback

handleUpdatedState = (delta, curstate) ->
	#Client plugins maybe modify state...
	for callback in stateUpdateCallbacks
		callback(delta, curstate)

	#sync back as long client plugins modify state
	sync()
