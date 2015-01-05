sessions = {}
shareLinks = {}

module.exports = (request, response, next) ->
	# if in /app, do we have a url parameter that indicates a session?
	if request.path == '/app' and request.query.s?
		sessionId = request.query.s
		checkSession sessionId, request, response, next
	else
		if request.cookies.s?
			sessionId = request.cookies.s
			checkSession sessionId, request, response, next
		else
			newSession request, response, next

checkSession = (sessionId, request, response, next) ->
	if sessions[sessionId]?
		# if in /app, redirect to /app?s=id (always show session id)
		if request.path == '/app' and not (request.query.s?)
			response.redirect '/app?s=' + sessionId
			return

		# apply session for further processing
		request.session = sessions[sessionId]
		response.cookie('s', sessionId)
		next()
	else
		#create a new session for invalid Ids and redirect
		newSession request, response, next

newSession = (request, response, next) ->
	request.session = generateSession()
	response.cookie('s', request.session.id)

	# only redirect if already in /app (but maybe with wrong session id)
	# prevents from redirection from mainpage etc
	if request.path == '/app'
		response.redirect '/app?s=' + request.session.id
	else
		next()

generateSession = () ->
	id = generateId()
	sessions[id] = {
		id: id
	}
	return sessions[id]

generateId = (length = 10) ->
	chars = '0123456789abcdefghijklmnopqrstuvwxyz'
	result = ''
	for i in [0..length - 1]
		index = Math.floor((Math.random() * chars.length))
		c = chars[index]
		result += c
	return result
