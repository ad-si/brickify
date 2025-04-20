import clone from "clone"

const sessions = {}
const shareLinks = {}

module.exports.middleware = function (request, response, next) {
  // if in /app, do we have a share url?
  let sessionId
  if ((request.path === "/app") && (request.query.share != null)) {
    sessionId = request.query.share
    return resolveShare(sessionId, request, response, next)
    // if in /app, do we have a url parameter that indicates a session?
  }
  else if ((request.path === "/app") && (request.query.s != null)) {
    sessionId = request.query.s
    return checkSession(sessionId, request, response, next)
    // do we have a cookie that indicates a session?
  }
  else if (request.cookies.s != null) {
    sessionId = request.cookies.s
    return checkSession(sessionId, request, response, next)
    // no session indication -> create a new session
  }
  else {
    return newSession(request, response, next)
  }
}

module.exports.generateShareId = function (sid) {
  // check if share id exists
  for (const key of Object.keys(shareLinks || {})) {
    if (shareLinks[key] === sid) {
      return key
    }
  }

  // create new one
  const id = generateId()
  shareLinks[id] = sid
  return id
}

var checkSession = function (sessionId, request, response, next) {
  // Does the session exist?
  if (sessions[sessionId] != null) {
    // if in /app, redirect to /app?s=id (always show session id)
    if ((request.path === "/app") && (request.query.s == null)) {
      response.redirect("/app?s=" + sessionId)
      return
    }

    // apply session for further processing
    request.session = sessions[sessionId]
    response.cookie("s", sessionId)
    return next()
  }
  else {
    // create a new session for invalid Ids and redirect
    return newSession(request, response, next)
  }
}

var resolveShare = function (shareId, request, response, next) {
  // Is this a valid share link?
  if (shareLinks[shareId] != null) {
    // create a new session with a copy of the shared state
    const sid = shareLinks[shareId]
    const session = sessions[sid]
    const cloned = clone(session)
    return newSession(request, response, next, cloned)
  }
  else {
    // invalid share id - generate new state
    return newSession(request, response, next)
  }
}

var newSession = function (request, response, next, sessionData = null) {
  request.session = generateSession(sessionData)
  response.cookie("s", request.session.id)

  // only redirect if already in /app (but maybe with wrong session id)
  // prevents from redirection from mainpage etc
  if (request.path === "/app") {
    return response.redirect("/app?s=" + request.session.id)
  }
  else {
    return next()
  }
}

var generateSession = function (sessionData = null) {
  const id = generateId()
  sessions[id] = sessionData || {}
  sessions[id].id = id
  return sessions[id]
}

var generateId = function (length) {
  if (length == null) {
    length = 10
  }
  const chars = "0123456789abcdefghijklmnopqrstuvwxyz"
  let result = ""
  for (let i = 0, end = length; i < end; i++) {
    const index = Math.floor(Math.random() * chars.length)
    const c = chars[index]
    result += c
  }
  return result
}
