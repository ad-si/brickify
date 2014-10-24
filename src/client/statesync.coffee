state = {test: "value"}
oldstate = {test: "value"}
globalConfigInstance = null

exports.state = state

exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig

exports.sync = () ->
	#Todo: json diff
	deltaState = state
	#Todo: deep copy state to old state to be able to diff later
	$.post("/statesync", {deltaState: deltaState, stateSession: globalConfigInstance.stateSession})
