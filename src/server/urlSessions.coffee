clone = require 'clone'

sessions = {}
shareLinks = {}

module.exports.middleware = (request, response, next) ->
	# if in /app, do we have a share url?
	if request.path == '/app' and request.query.share?
		sessionId = request.query.share
		resolveShare sessionId, request, response, next
	# if in /app, do we have a url parameter that indicates a session?
	else if request.path == '/app' and request.query.s?
		sessionId = request.query.s
		checkSession sessionId, request, response, next
	# do we have a cookie that indicates a session?
	else if request.cookies.s?
		sessionId = request.cookies.s
		checkSession sessionId, request, response, next
	# no session indication -> create a new session
	else
		newSession request, response, next

module.exports.generateShareId = (sid) ->
	# check if share id exists
	for own key of shareLinks
		if shareLinks[key] == sid
			return key

	# create new one
	id = generateId()
	shareLinks[id] = sid
	return id

checkSession = (sessionId, request, response, next) ->
	# Does the session exist?
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
		# create a new session for invalid Ids and redirect
		newSession request, response, next

resolveShare = (shareId, request, response, next) ->
	# Is this a valid share link?
	if shareLinks[shareId]?
		#create a new session with a copy of the shared state
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
	sessions[id] = sessionData or {}
	sessions[id].id = id
	return sessions[id]

generateId = (length = 10) ->
	chars = '0123456789abcdefghijklmnopqrstuvwxyz'
	result = ''
	for i in [0...length] by 1
		index = Math.floor((Math.random() * chars.length))
		c = chars[index]
		result += c
	return result
