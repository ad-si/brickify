$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()
		@_selectedBrush = false
		@_downloadEventListener = []

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

		@_addDownloadButtonUi()

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer brushdeselect"><img src="img/' +
			brush.icon + '"><br><span>' +
			brush.text + '</span></div>'
		brushelement = $(html)
		brushelement.on 'click', () => @_handleBrushClicked brush, brushelement

		return brushelement

	addDownloadListener: (callback) =>
		@_downloadEventListener.push callback

	_addDownloadButtonUi: =>
		html = '<div class="btn-success brushcontainer">
			<img src="img/downloadBrush.png">
			</span><br><span>Download</span></div>'
		brushelement = $(html)

		brushelement.on 'click', () =>
			for dl in @_downloadEventListener
				dl()

		@_toolbarContainer.append brushelement

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
			@_selectedBrush.jqueryElement.addClass 'brushdeselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = null
				return

		@_selectedBrush = brush
		@_selectedBrush.selectCallback? @_selectedNode() if @_selectedNode()?
		@_selectedBrush.jqueryElement.removeClass 'brushdeselect'
		@_selectedBrush.jqueryElement.addClass 'brushselect'
