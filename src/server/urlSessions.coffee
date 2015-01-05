clone = require 'clone'

sessions = {}
shareLinks = {}

module.exports.middleware = (request, response, next) ->
	# if in /app, do we have a url parameter that indicates a session?
	if request.path == '/app' and request.query.s?
		sessionId = request.query.s

		if sessionId.indexOf('Share-') == 0
			resolveShare sessionId, request, response, next
		else
			checkSession sessionId, request, response, next
	else
		if request.cookies.s?
			sessionId = request.cookies.s
			checkSession sessionId, request, response, next
		else
			newSession request, response, next

module.exports.generateShareId = (sid) ->
	id = 'Share-' + generateId()
	shareLinks[id] = sid
	return id

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

resolveShare = (shareId, request, response, next) ->

	if shareLinks[shareId]?
		#create a copy of original state
		sid = shareLinks[shareId]
		session = sessions[sid]
		cloned = clone(session)
		newSession(request, response, next, cloned)
	else
		#invalid share id - generate new state
		newSession request, response, next

newSession = (request, response, next, sessionData = null) ->
	request.session = generateSession(sessionData)
	response.cookie('s', request.session.id)

	# only redirect if already in /app (but maybe with wrong session id)
	# prevents from redirection from mainpage etc
	if request.path == '/app'
		response.redirect '/app?s=' + request.session.id
	else
		next()

generateSession = (sessionData = null) ->
	id = generateId()
	if sessionData?
		#take data, but override with new session id
		sessions[id] = sessionData
		sessions[id].id = id
	else
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
