$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()
		@_selectedBrush = false

	handleMouseDown: (event) =>
		if @_selectedBrush and @_selectedNode()?
			@_selectedBrush.mouseDownCallback event, @_selectedNode()

	handleMouseMove: (event) =>
		if @_selectedBrush and @_selectedNode()?
			@_selectedBrush.mouseMoveCallback? event, @_selectedNode()

	handleMouseUp: (event) =>
		if @_selectedBrush and @_selectedNode()?
			@_selectedBrush.mouseUpCallback? event, @_selectedNode()

	_createBrushList: =>
		@_brushes = @bundle.pluginHooks.getBrushes().reduce(
			(brushes, b) -> brushes.concat b
		)

		$toolbar = $('#toolbar')
		for brush in @_brushes
			brush.jqueryElement = @_createBrushUi brush
			$toolbar.append brush.jqueryElement

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer"><img src="img/' +
			brush.icon + '" width="64px" height="64px"><br><span>' +
			brush.text + '</span></div>'
		brushelement = $(html)
		brushelement.on 'click', () => @_handleBrushClicked brush, brushelement

		return brushelement

	onNodeSelect: (selectedNode) =>
		if @_selectedBrush and selectedNode?
				@_selectedBrush.selectCallback? selectedNode

	_selectedNode: () =>
		return @bundle.ui.sceneManager.selectedNode

	hasBrushSelected: () =>
		return !!@_selectedBrush # convert to strict boolean type

	_handleBrushClicked: (brush, jqueryElement) =>
		if @_selectedBrush
			if @_selectedNode()?
				@_selectedBrush.deselectCallback? @_selectedNode()

			@_selectedBrush.jqueryElement.removeClass 'brushselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = null
				return

		@_selectedBrush = brush
		@_selectedBrush.selectCallback? @_selectedNode() if @_selectedNode()?
		@_selectedBrush.jqueryElement.addClass 'brushselect'
