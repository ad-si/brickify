$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()

	handleClick: (event) =>
		if @_selectedBrush
			if @_selectedBrush.clickCallback?
				@_selectedBrush.clickCallback(event)

	handleMove: (event) =>
		if @_selectedBrush
			if @_selectedBrush.moveCallback?
				@_selectedBrush.moveCallback(event)

	hasBrushSelected: () =>
		return true if  @_selectedBrush?
		return false

	_createBrushList: =>
		returnArrays = @bundle.pluginHooks.getBrushes()
		@_brushes = []

		for array in returnArrays
			for b in array
				@_brushes.push b

		for brush in @_brushes
			jqueryElement = @_createBrushUi brush
			brush.jqueryElement = jqueryElement

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer"><span class="glyphicon glyphicon-' +
			brush.icon + '"></span><br><span>' + brush.text + '</span></div>'
		brushelement = $(html)
		brushelement.on 'click', () =>
			@_handleBrushClicked brush, brushelement
		$('#toolbar').append(brushelement)

		return brushelement

	_handleBrushClicked: (brush, jqueryElement) =>
		if @_selectedBrush?
			if @_selectedBrush.deselectCallback?
				@_selectedBrush.deselectCallback()

			@_selectedBrush.jqueryElement.removeClass 'brushselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = null
				return

		@_selectedBrush = brush
		
		if @_selectedBrush.selectCallback?
			@_selectedBrush.selectCallback()

		@_selectedBrush.jqueryElement.addClass 'brushselect'
