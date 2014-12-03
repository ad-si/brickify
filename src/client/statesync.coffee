###
# @module stateSynchronization
###

jsondiffpatch = require 'jsondiffpatch'
#compare objects in arrays by using json.stringify
diffpatch = jsondiffpatch.create objectHash: (obj) ->
	return JSON.stringify(obj)

pluginHooks = require '../common/pluginHooks'

class Statesync
	constructor: (@syncWithServer = true) ->
		@state = {}
		@oldState = {}
		@globalConfig = null
		@initialStateIsLoaded = false
		@initialStateLoadedCallbacks = []

	init: (globalConfig, stateInitializedCallback) ->
		self = @
		@globalConfig = globalConfig
		$.get '/statesync/get', {}, (data, textStatus, jqXHR) ->
			self.state = data
			self.oldState = JSON.parse JSON.stringify self.state

			console.log "Got initial state from server: #{JSON.stringify(self.state)}"

			stateInitializedCallback self.state if stateInitializedCallback?

			initialStateIsLoaded = true
			self.initialStateLoadedCallbacks.forEach (callback) ->
				callback(state)
			self.handleUpdatedState self.state

	getState: (callback) ->
		if @initialStateIsLoaded
			callback(@state)
		else
			@initialStateLoadedCallbacks.push(callback)

	# executes callback(state) and then synchronizes the state with the server.
	# if updatedStateEvent is set to true, the updateState hook of all client
	# plugins will be called before synchronization with the server
	performStateAction: (callback, updatedStateEvent = false) ->
		callback(@state)

		# let every plugin do something with the updated state
		# before syncing it to the server
		if updatedStateEvent
			@handleUpdatedState @state
		else
			@sync()

	handleUpdatedState: (curstate) ->
		self = @
		numCallbacks = pluginHooks.get('onStateUpdate').length
		numCalledDone = 0

		done = () ->
			#if all plugins finished modifying their state, synchronize
			numCalledDone++
			if numCallbacks == numCalledDone
				# sync as long client plugins modify the state
				self.sync()

		#Client plugins maybe modify state...
		pluginHooks.onStateUpdate curstate, done
		

	sync: (force = false) ->
		# if we shall not sync with the server, run the loop internally as long as
		# plugins change the state
		if not @syncWithServer
			@oldState = JSON.parse JSON.stringify @state
			@handleUpdatedState @state

			delta = diffpatch.diff @oldState, @state
			while delta != null
				@handleUpdatedState @state
				delta = diffpatch.diff @oldState, @state
				@oldState = JSON.parse JSON.stringify @state
			return

		delta = diffpatch.diff @oldState, @state

		if not force
			if not delta?
				return

		# deep copy
		@oldState = JSON.parse JSON.stringify @state

		console.log "Sending delta to server: #{JSON.stringify(delta)}"
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
				console.log "Got delta from server: #{JSON.stringify(delta)}"

				clientDelta = diffpatch.diff @oldState, @state

				if clientDelta?
					console.log 'The client modified its state
						while the server worked, this should not happen!'

				#patch state with server changes
				diffpatch.patch @state, delta

				#deep copy current state
				@oldState = JSON.parse JSON.stringify @state

				@handleUpdatedState @state

module.exports.Statesync = Statesync

defaultInstance = new Statesync()

# backwards compatibility for plugins that use statesync.performStateAction
# directly
module.exports.defaultInstance = defaultInstance
module.exports.performStateAction = (callback, updatedStateEvent = false) ->
	console.warn 'performStateAction should not be used anymore, use async code
and done() in onStateUpdate instead'
	defaultInstance.performStateAction(callback, updatedStateEvent)
