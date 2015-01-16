path = require 'path'

module.exports.getLandingpage = (request, response) ->
	response.render path.join('landingpage','landingpage')

module.exports.getContribute = (request, response) ->
	response.render path.join('landingpage','contribute')

module.exports.getTeam = (request, response) ->
	response.render path.join('landingpage','team')
