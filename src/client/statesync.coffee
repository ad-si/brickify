###
# @module stateSynchronization
###

$ = require 'jquery'
objectTree = require '../common/objectTree'
diffHelper = require '../common/stateDiffHelper'
diffpatch = diffHelper.createJsonDiffPatch()
clone = require 'clone'


module.exports = class Statesync
	constructor: (@bundle) ->
		@syncWithServer = @bundle.globalConfig.syncWithServer
		if(@syncWithServer)
			@statePromise = Promise.resolve($.get '/statesync/get')
		else
			@statePromise = Promise.resolve {}

		@state = {}
		@oldState = {}

		@$spinnerContainer = $('#spinnerContainer')

	init: ->
		@statePromise.then((data) =>
			@state = data
			@oldState = clone(@state)
			console.log "Got initial state from server: #{JSON.stringify(@state)}"
			objectTree.init @state
			@unlockState()
		)

	# executes callback(state) and then synchronizes the state with the server.
	# if updatedStateEvent is set to true, the updateState hook of all client
	# plugins will be called before synchronization with the server
	performStateAction: (callback, updatedStateEvent = false) =>
		prom = @statePromise.then(callback)
		if(updatedStateEvent)
			prom = prom.then(@handleUpdatedState)
		@statePromise = prom.then(@sync)

	handleUpdatedState: =>
		Promise.all(@bundle.pluginHooks.onStateUpdate @state)
			.then(() => @bundle.onStateUpdate @state)

	sync: =>
		# do we need to sync?
		delta = diffpatch.diff @oldState, @state
		if not delta?
			return @state

		# are we supposed to sync?
		if not @syncWithServer
			@oldState = clone(@state)
			return handleUpdatedState().then(Promise.resolve @state)

		# both yes -> sync!
		@lockState()
		return @syncToServer(delta).then(@syncFromServer).then(() =>
			@unlockState()
			return @state
		)

	syncToServer: (delta) =>
		# deep copy
		@oldState = clone(@state)

		console.log "Sending delta to server: #{JSON.stringify(delta)}"
		return Promise.resolve($.ajax '/statesync/set',
				type: 'POST'
				data: JSON.stringify({deltaState: delta})
				# what jquery expects as an answer
				dataType: 'json'
				# what is sent in the post request as a header
				contentType: 'application/json; charset=utf-8'
		)

	syncFromServer: (delta) =>
		# if the server has done no changes, we're done as well
		if delta.emptyDiff
			return Promise.resolve()

		# if the server has done changes, we have to patch our state
		# and notify all plugins
		console.log "Got delta from server: #{JSON.stringify(delta)}"

		clientDelta = diffpatch.diff @oldState, @state

		if clientDelta?
			throw new Error('The client modified its state
						while the server worked, this should not happen!')

		# patch state with server changes
		diffpatch.patch @state, delta

		# deep copy current state for change-checking
		@oldState = clone(@state)

		# notify plugins
		return @handleUpdatedState()

	lockState: () =>
		@$spinnerContainer.show()

	unlockState: () =>
		@$spinnerContainer.fadeOut()
