class UiObjects
	constructor: (@bundle) ->
		@selectedNode = null

		@_brushList = []

		for array in @bundle.pluginHooks.getBrushes()
			for brush in array
				@_brushList.push brush

	init: (jqueryString, brushjQueryString, visibilityjQueryString) =>
		@jqueryObject = $(jqueryString)

		@_createBrushUi brushjQueryString

	onNodeSelect: (node) =>
		@selectedNode = node

		if not @_selectedBrush and @_brushList.length > 0
			@_brushSelect @_brushList[@_brushList.length - 1]

	onNodeDeselect: (node) =>
		@_deselectBrush node
		@selectedNode = null

	_createBrushUi: (brushjQueryString) =>
		@_selectedBrush = null

		@brushContainer = $(brushjQueryString)

		for brush in @_brushList
			htmlContainer = @brushContainer.find brush.containerId
			brush.jqueryObject = htmlContainer
			@_bindBrushEvent brush
			
	_bindBrushEvent: (brush) ->
		brush.jqueryObject.on 'click', () => @_brushSelect brush

	
	_brushSelect: (brush) =>
		# deselect currently selected brush
		@_deselectBrush @selectedNode

		#select new brush
		@_selectedBrush = brush
		brush.jqueryObject.addClass 'active'
		brush.selectCallback? @selectedNode

	_deselectBrush: (node) =>
		if @_selectedBrush?
			@_selectedBrush.deselectCallback? node
			@_selectedBrush.jqueryObject.removeClass 'active'
			@_selectedBrush = null

	getSelectedBrush: =>
		return @_selectedBrush

	toggleBrush: =>
		for brush in @_brushList
			if brush isnt @_selectedBrush
				@_brushSelect brush
				return true
		return false

module.exports = UiObjects
