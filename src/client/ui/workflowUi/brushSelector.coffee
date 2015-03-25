###
# @class BrushSelector
###
class BrushSelector
	constructor: (@bundle) ->
		@selectedNode = null

		@_brushList = []

		for array in @bundle.pluginHooks.getBrushes()
			for brush in array
				@_brushList.push brush

	init: (jQueryBrushContainerSelector) =>
		@_selectedBrush = null
		@_bigBrushSelected = false

		@brushContainer = $(jQueryBrushContainerSelector)

		for brush in @_brushList
			htmlContainer = @brushContainer.find brush.containerId
			brush.brushButton = htmlContainer
			brush.bigBrushButton = brush.brushButton.find '.bigBrush'
			@_bindBrushEvent brush

	onNodeSelect: (node) =>
		@selectedNode = node

		if not @_selectedBrush and @_brushList.length > 0
			@_bigBrushSelected = false
			@_brushSelect @_brushList[@_brushList.length - 1]

	onNodeDeselect: (node) =>
		@_deselectBrush node
		@selectedNode = null

	_bindBrushEvent: (brush) ->
		brush.brushButton.on 'click', (event) =>
			@_bigBrushSelected = event.shiftKey
			@_brushSelect brush
		brush.bigBrushButton.on 'click', (event) =>
			if brush is @_selectedBrush
				@_bigBrushSelected = !@_bigBrushSelected
			else
				@_bigBrushSelected = true
			@_brushSelect brush
			event.stopImmediatePropagation()

	_brushSelect: (brush) =>
		# deselect currently selected brush
		@_deselectBrush @selectedNode

		#select new brush
		@_selectedBrush = brush
		brush.brushButton.addClass 'active'
		brush.bigBrushButton.addClass 'active' if @_bigBrushSelected
		brush.selectCallback? @selectedNode, @_bigBrushSelected

	_deselectBrush: (node) =>
		if @_selectedBrush?
			@_selectedBrush.deselectCallback? node
			@_selectedBrush.brushButton.removeClass 'active'
			@_selectedBrush.bigBrushButton.removeClass 'active'
			@_selectedBrush = null

	getSelectedBrush: =>
		return @_selectedBrush

	toggleBrush: =>
		for brush in @_brushList
			if brush isnt @_selectedBrush
				@_brushSelect brush
				return true
		return false

module.exports = BrushSelector
