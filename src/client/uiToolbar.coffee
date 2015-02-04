$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle, @selection) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()
		@_selectedBrush = false
		@_downloadEventListener = []

		@selection.selectionChange (selectedNode) =>
			@_handleNodeSelected selectedNode

	handleMouseDown: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseDownCallback?
				@_selectedBrush.mouseDownCallback event, @selection.selectedNode

	handleMouseMove: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseMoveCallback?
				@_selectedBrush.mouseMoveCallback event, @selection.selectedNode

	handleMouseUp: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseUpCallback?
				@_selectedBrush.mouseUpCallback event, @selection.selectedNode

	hasBrushSelected: () =>
		return true if  @_selectedBrush
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

		@_addDownloadButtonUi()

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer brushdeselect"><img src="img/' +
			brush.icon + '"><br><span>' +
			brush.text + '</span></div>'
		brushelement = $(html)
		brushelement.on 'click', () =>
			@_handleBrushClicked brush, brushelement
		@_toolbarContainer.append(brushelement)

		return brushelement

	addDownloadListener: (callback) =>
		@_downloadEventListener.push callback

	_addDownloadButtonUi: =>
		html = '<div class="btn-success brushcontainer">
			<img src="img/downloadBrush.png">
			</span><br><span>Download</span></div>'
		brushelement = $(html)

		brushelement.on 'click', () =>
			for c in @_downloadEventListener
				c()

		@_toolbarContainer.append(brushelement)


	_handleNodeSelected: (selectedNode) =>
		if selectedNode?
			if @_selectedBrush
				if @_selectedBrush.selectCallback?
					@_selectedBrush.selectCallback selectedNode

	_handleBrushClicked: (brush, jqueryElement) =>
		if @_selectedBrush
			if @_selectedBrush.deselectCallback? and @selection.selectedNode?
				@_selectedBrush.deselectCallback @selection.selectedNode

			@_selectedBrush.jqueryElement.removeClass 'brushselect'
			@_selectedBrush.jqueryElement.addClass 'brushdeselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = false
				return

		@_selectedBrush = brush
		
		if @_selectedBrush.selectCallback? and @selection.selectedNode?
			@_selectedBrush.selectCallback @selection.selectedNode

		@_selectedBrush.jqueryElement.removeClass 'brushdeselect'
		@_selectedBrush.jqueryElement.addClass 'brushselect'
