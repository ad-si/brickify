#Todo: connect to a real database (only supports one state instance at the moment)
dbstate = {}

exports.saveState = (sessionId, state) ->
	dbstate = state;

exports.retrieveState = (sessionId, stateCallback) ->
	stateCallback(dbstate);