piwikTracking = require '../../piwikTracking'

###
# @class EditBrushUi
###
class EditBrushUi
	constructor: (@workflowUi) ->
		@selectedNode = null

		@_brushList = []

	setBrushes: (@_brushList) =>
		for brush in @_brushList
			brush.brushButton = @brushContainer.find brush.containerId
			brush.bigBrushButton = @bigBrushContainer.find brush.containerId
			@_bindBrushEvent brush

	init: (jQueryBrushContainerSelector, jQueryBigBrushContainerSelector) =>
		@_selectedBrush = null
		@_bigBrushSelected = false

		@brushContainer = $(jQueryBrushContainerSelector)
		@bigBrushContainer = $(jQueryBigBrushContainerSelector)

		# because firefox ignores the draggable="false" attribute
		# attached to the brush images
		$('#brushContainer img').on 'dragstart', -> return false
		$('#bigBrushContainer img').on 'dragstart', -> return false

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
			@_bigBrushSelected = false
			@_brushSelect brush
			@workflowUi.hideMenuIfPossible()
		brush.bigBrushButton.on 'click', (event) =>
			@_bigBrushSelected = true
			@_brushSelect brush
			@workflowUi.hideMenuIfPossible()

	_brushSelect: (brush) =>
		# deselect currently selected brush
		@_deselectBrush @selectedNode

		# piwik select event
		big = ''
		big = 'Big' if @_bigBrushSelected
		piwikTracking.trackEvent 'Editor', 'BrushSelect', brush.containerId + big

		#select new brush
		@_selectedBrush = brush
		brush.brushButton.addClass 'active' if not @_bigBrushSelected
		brush.bigBrushButton.addClass 'active' if @_bigBrushSelected
		brush.onBrushSelect? @selectedNode, @_bigBrushSelected

	_deselectBrush: (node) =>
		if @_selectedBrush?
			@_selectedBrush.onBrushDeselect? node
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

module.exports = EditBrushUi
