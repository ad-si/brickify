path = require 'path'

module.exports = (request, response) ->
	if request.query.ui? and request.query.ui == 'tabs'
		response.render path.join('app','app_tab')
	else
		response.render path.join('app','app')
