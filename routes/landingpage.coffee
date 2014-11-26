path = require 'path'

links = {}

module.exports.setLinks = (_links) ->
	links = _links

module.exports.getLandingpage = (request, response) ->
	response.render path.join('landingpage','landingpage'), links
