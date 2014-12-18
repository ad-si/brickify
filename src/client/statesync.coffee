###
# @module stateSynchronization
###


$ = require 'jquery'
jsondiffpatch = require 'jsondiffpatch'
clone = require 'clone'
#compare objects in arrays by using json.stringify
diffpatch = jsondiffpatch.create objectHash: (obj) ->
	return JSON.stringify(obj)

module.exports = class Statesync
	constructor: (bundle, @syncWithServer = true) ->
		if(@syncWithServer)
			@statePromise = Promise.resolve($.get '/statesync/get')
		else
			@statePromise = Promise.resolve {}

		@state = {}
		@oldState = {}
		@globalConfig = bundle.globalConfig
		@pluginHooks = bundle.pluginHooks
		@stateIsLocked = false
		@stateActionWaitingCallbacks = []

		@$spinnerContainer = $('#spinnerContainer')

	init: (stateInitializedCallback) ->
		@statePromise.then((data) =>
			@state = data
			@oldState = clone(@state)

			console.log "Got initial state from server: #{JSON.stringify(@state)}"

			stateInitializedCallback? @state

			@performInitialStateLoadedAction()
		)

	performInitialStateLoadedAction: () ->
		@unlockState()
		@handleUpdatedState @state

	getState: ->
		return @statePromise

	# executes callback(state) and then synchronizes the state with the server.
	# if updatedStateEvent is set to true, the updateState hook of all client
	# plugins will be called before synchronization with the server
	performStateAction: (callback, updatedStateEvent = false) =>
		# add callbacks to a waiting list if state is currently
		# being synced to the server
		if @stateIsLocked
			@stateActionWaitingCallbacks.push callback
			return

		callback(@state)

		# let every plugin do something with the updated state
		# before syncing it to the server
		if updatedStateEvent
			@handleUpdatedState @state
		else
			@sync()

	handleUpdatedState: (curstate) ->
		numCallbacks = @pluginHooks.get('onStateUpdate').length
		numCalledDone = 0

		done = () =>
			#if all plugins finished modifying their state, synchronize
			numCalledDone++
			if numCallbacks == numCalledDone
				# sync as long client plugins modify the state
				@sync()

		#Client plugins maybe modify state...
		@pluginHooks.onStateUpdate curstate, done


	sync: (force = false) =>
		delta = diffpatch.diff @oldState, @state

		if not force
			if not delta?
				return

		# if we shall not sync with the server, run the loop internally as long as
		# plugins change the state
		if not @syncWithServer
			@oldState = clone(@state)
			@handleUpdatedState @state
			return

		# lock state until a response from the server arrives
		@lockState()

		# deep copy
		@oldState = clone(@state)

		console.log "Sending delta to server: #{JSON.stringify(delta)}"
		Promise.resolve($.ajax '/statesync/set',
			type: 'POST'
			data: JSON.stringify({deltaState: delta})
		# what jquery expects as an answer
			dataType: 'json'
		# what is sent in the post request as a header
			contentType: 'application/json; charset=utf-8'
		# check whether client modified its local state
		# since the post request was sent
		).then((data) =>
				delta = data

				if delta.emptyDiff == true
					delta = null

				if delta
					# handle modified state from server
					console.log "Got delta from server: #{JSON.stringify(delta)}"

					clientDelta = diffpatch.diff @oldState, @state

					if clientDelta?
						throw new Error('The client modified its state
							while the server worked, this should not happen!')

					#patch state with server changes
					diffpatch.patch @state, delta
					@statePromise = Promise.resolve(@state)

					#deep copy current state
					@oldState = clone(@state)

					@unlockState()

					#run all waiting callbacks
					for cb in @stateActionWaitingCallbacks
						cb @state
					@stateActionWaitingCallbacks = []

					@handleUpdatedState @state
				else
					# state was not modified, but there may be waiting callbacks
					@unlockState()

					if @stateActionWaitingCallbacks.length > 0
						for cb in @stateActionWaitingCallbacks
							cb @state
						@stateActionWaitingCallbacks = []
						@handleUpdatedState @state
		)

	lockState: () ->
		@stateIsLocked = true
		@$spinnerContainer.show()

	unlockState: () ->
		@stateIsLocked = false
		@$spinnerContainer.fadeOut()
