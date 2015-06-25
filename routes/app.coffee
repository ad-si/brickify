path = require 'path'

module.exports = (request, response) ->
	response.render path.join('app', 'app'), {
		page: 'editor'
		pageTitle: 'editor'
		piwikEnabled: request.app.get('env') isnt 'development'
	}
