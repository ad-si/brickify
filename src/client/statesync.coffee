###
# @module stateSynchronization
###


$ = require 'jquery'
objectTree = require '../common/objectTree'
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

	init: ->
		@statePromise.then((data) =>
			@state = data
			@oldState = clone(@state)

			console.log "Got initial state from server: #{JSON.stringify(@state)}"
			objectTree.init @state
			@unlockState()
		)

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
			@handleUpdatedState()
		else
			@sync()

	handleUpdatedState: ->
		Promise.all(@pluginHooks.onStateUpdate @state).then(@sync)

	sync: =>
		if not @syncWithServer
			@oldState = clone(@state)
			return
		@syncToServer().then(@syncFromServer)

	syncToServer: () =>
		delta = diffpatch.diff @oldState, @state

		if not delta?
			return Promise.resolve({emptyDiff: true})

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
		)

	syncFromServer: (delta) =>
		unless delta.emptyDiff
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

			@handleUpdatedState()
		else
			# state was not modified, but there may be waiting callbacks
			@unlockState()

			if @stateActionWaitingCallbacks.length > 0
				for cb in @stateActionWaitingCallbacks
					cb @state
				@stateActionWaitingCallbacks = []
				@handleUpdatedState()

	lockState: () =>
		@stateIsLocked = true
		@$spinnerContainer.show()

	unlockState: () =>
		@stateIsLocked = false
		@$spinnerContainer.fadeOut()
