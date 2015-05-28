path = require 'path'

module.exports.getLandingpage = (request, response) ->
	response.render path.join('landingpage','landingpage'), page: 'landing'

module.exports.getContribute = (request, response) ->
	response.render path.join('landingpage','contribute'), pageTitle: 'contribute'

module.exports.getTeam = (request, response) ->
	response.render path.join('landingpage','team'), pageTitle: 'team'

module.exports.getImprint = (request, response) ->
	response.render path.join('landingpage','imprint'), pageTitle: 'imprint'

module.exports.getEducators = (request, response) ->
	response.render path.join('landingpage','educators'), {page:'landing', pageTitle: 'educators'}
