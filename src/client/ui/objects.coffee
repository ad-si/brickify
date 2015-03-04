objectTree = require '../../common/state/objectTree'

class UiObjects
	constructor: (@bundle) ->
		@objectList = []
		@selectedStructure = null

		@_brushList = []
		for array in @bundle.pluginHooks.getBrushes()
			for brush in array
				@_brushList.push brush

	init: (jqueryString, brushjQueryString, visibilityjQueryString) =>
		@ui = @bundle.ui
		@jqueryObject = $(jqueryString)
		@_createBrushUi brushjQueryString

	# Called by sceneManager when a node is added
	onNodeAdd: (node) =>
		structure = {
			node: node
		}

		@_createUi(structure)

		@objectList.push structure
		@jqueryObject.append structure.ui

		@_objectSelect structure

		# make sure a brush is always selected
		if not @_selectedBrush
			@_brushSelect @_brushList[@_brushList.length - 1]

	# Called by sceneManager when a node is removed
	onNodeRemove: (node) =>
		for i in [0...@objectList.length] by 1
			structure = @objectList[i]
			if structure.node == node
				structure.ui.remove()
				@objectList.splice(i, 1)

				if @objectList.length > 0
					@_objectSelect @objectList[@objectList.length - 1]
				return

	# overrides the node selection
	onNodeSelect: (node) =>
		return if node is @selectedStructure.node

		for structure in @objectList
			if structure.node == node
				@_objectSelect structure, true
				return

	hideBrushContainer: =>
		@brushContainer.hide()

	showBrushContainer: =>
		@brushContainer.show()

	_createBrushUi: (brushjQueryString) =>
		@_selectedBrush = null

		@brushContainer = $(brushjQueryString)

		for brush in @_brushList
			brush.jqueryObject = @_createBrush brush
			@brushContainer.append brush.jqueryObject

	_createUi: (structure) =>
		name = structure.node.fileName

		html = "<li class='objectListItem'><p>#{name}</p></li>"
		structure.ui = $(html)

		structure.ui.on 'click', () =>
			@_objectSelect(structure)

	# creates a default brush with list entry
	_createBrush: (brush) =>
		string = "<div class='btn btn-primary'>
								#{brush.text}<br>
								<img src='img/#{brush.icon}' width='64' height='64' />
							</div>"

		htmlElement = $(string)
		htmlElement.on 'click', () => @_brushSelect brush

		return htmlElement

	_objectSelect: (structure, sceneManagerEvent = false) =>
		# Don't do anything when clicking on selected object
		return if structure is @selectedStructure

		# deselect previously selected object
		if @selectedStructure?
			@ui.sceneManager.deselect @selectedStructure.node
			@selectedStructure.ui.removeClass('selectedObject')
			@_deselectBrush @selectedStructure.node

		# select current object
		@selectedStructure = structure
		@ui.sceneManager.select @selectedStructure.node unless sceneManagerEvent
		@selectedStructure.ui.addClass('selectedObject')

	# deselect currently selected brush
	_brushSelect: (brush) =>
		if @_selectedBrush?
			@_selectedBrush.deselectCallback? @selectedStructure.node
			@_selectedBrush.jqueryObject.removeClass 'active'

		#select new brush
		@_selectedBrush = brush
		brush.jqueryObject.addClass 'active'
		brush.selectCallback? @selectedStructure.node

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
				return

module.exports = UiObjects
