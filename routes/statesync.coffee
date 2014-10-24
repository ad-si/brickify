exports.getState = (request, response) ->
	response.send("State!")
	return

exports.setState = (request, response) ->
	response.send("State saved! (state is: " + JSON.stringify(request.body.deltaState) + ")");
	return;