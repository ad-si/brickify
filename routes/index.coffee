module.exports = (links) ->

	return (request, response) ->
		response.render 'index', links
