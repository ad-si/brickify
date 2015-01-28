$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()

	_createBrushList: =>
		returnArrays = @bundle.pluginHooks.getBrushes()
		brushes = []

		for array in returnArrays
			for b in array
				brushes.push b

		for brush in brushes
			@_createBrushUi brush

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer"><span class="glyphicon glyphicon-' +
			brush.icon + '"></span><br><span>' + brush.text + '</span></div>'
		brushelement = $(html)
		$('#toolbar').append(brushelement)
