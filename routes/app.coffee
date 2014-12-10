path = require 'path'

module.exports = (links) ->

	return (request, response) ->
		response.render path.join('app','app'), links
