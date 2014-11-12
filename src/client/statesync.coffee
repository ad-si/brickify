###
# @module stateSynchronization
###

jsondiffpatch = require 'jsondiffpatch'
#compare objects in arrays by using json.stringify
diffpatch = jsondiffpatch.create objectHash: (obj) ->
	return JSON.stringify(obj)

pluginHooks = require './pluginHooks'

state = {}
oldState = {}

globalConfigInstance = null
stateUpdateCallbacks = []

exports.getState = () ->
	return state

exports.performStateAction = (callback) ->
	callback(state)
	sync()

exports.init = (globalConfig, stateInitializedCallback) ->
	globalConfigInstance = globalConfig
	$.get "/statesync/get", {}, (data, textStatus, jqXHR) ->
		state = data
		oldState = JSON.parse JSON.stringify state
		console.log "Got initial state from server: " + JSON.stringify(state)
		stateInitializedCallback state if stateInitializedCallback?
		handleUpdatedState({}, state)

sync = (force = false) ->
	delta = diffpatch.diff oldState, state

	if not force
		if not delta?
			return

	# deep copy
	oldState = JSON.parse JSON.stringify state

	console.log "Sending delta to server:" + JSON.stringify(delta)

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
			delta = data
			console.log "Got delta from server: " + JSON.stringify(delta)

			clientDelta = diffpatch.diff oldState, state
			if clientDelta?
				console.log 'The client modified its state' +
					'while the server worked, this should not happen!'

			#patch state with server changes
			diffpatch.patch state, delta

			#deep copy current state
			oldState = JSON.parse JSON.stringify state

			handleUpdatedState(delta, state)

exports.sync = sync

exports.addUpdateCallback = (callback) ->
	stateUpdateCallbacks.push callback

handleUpdatedState = (delta, curstate) ->
	#Client plugins maybe modify state...
	pluginHooks.updateState delta, curstate

	#sync back as long client plugins modify state
	sync()
