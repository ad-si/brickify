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
		html = '<div class="brushlayout">
			<span class="glyphicon glyphicon-eye-open visibilityIcon"></span>
			<br><div class="brushcontainer"><img src="img/' +
			brush.icon + '"><br><span>' +
			brush.text + '</span></div></div>'
		brushelement = $(html)

		button = brushelement.find('.brushcontainer')
		visibility = brushelement.find('.visibilityIcon')

		if brush.canToggleVisibility and brush.visibilityCallback?
			visibility.on 'click', () => @_handleVisibilityClicked brush, visibility
			brush.visible = true
		else
			visibility.hide()

		button.on 'click', () => @_handleBrushClicked brush, button

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

			jqueryElement.removeClass 'brushselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = null
				return

		@_selectedBrush = brush
		@_selectedBrush.selectCallback? @_selectedNode() if @_selectedNode()?
		jqueryElement.addClass 'brushselect'

	_handleVisibilityClicked: (brush, jqueryElement) =>
		brush.visible = !brush.visible

		jqueryElement.removeClass('glyphicon-eye-open')
		jqueryElement.removeClass('glyphicon-eye-close')

		if brush.visible
			jqueryElement.addClass('glyphicon-eye-open')
		else
			jqueryElement.addClass('glyphicon-eye-close')

		brush.visibilityCallback brush.visible

