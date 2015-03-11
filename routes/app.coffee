path = require 'path'

module.exports = (request, response) ->
	response.render path.join('app','app')
