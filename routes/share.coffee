urlSessions = require '../src/server/urlSessions'

module.exports = (request, response) ->
	if request.session?
		id = urlSessions.generateShareId(request.session.id)
		response.send id
	else
		response.status(400)
		.send '400: You don\'t have a session cookie associated with you (yet)'
