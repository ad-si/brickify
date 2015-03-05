path = require 'path'

module.exports = (request, response) ->
	if request.query.ui? and request.query.ui == 'tabs'
		tabSidebar = true
	else
		tabSidebar = false

	response.render path.join('app','app'), {tabSidebar: tabSidebar}
