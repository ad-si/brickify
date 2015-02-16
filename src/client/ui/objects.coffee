objectTree = require '../../common/state/objectTree'

module.exports = class UiObjects
	constructor: (@bundle) ->
		@objectList = []
		@selectedStructure = null

		@_brushList = []
		for array in @bundle.pluginHooks.getBrushes()
			for brush in array
				@_brushList.push brush

	init: (jqueryString, brushjQueryString) =>
		@ui = @bundle.ui
		@jqueryObject = $(jqueryString)
		@selectCallback = @ui.sceneManager.select
		@deselectCallback = @ui.sceneManager.deselect
		@_createBrushUi brushjQueryString

	onNodeAdd: (node) =>
		# Called by sceneManager when a node is added
		structure = {
			node: node
		}

		@_createUi(structure)

		@objectList.push structure
		@jqueryObject.append structure.ui

		@_objectSelect structure


	onNodeRemove: (node) =>
		# Called by sceneManager when a node is removed
		for i in [0..@objectList.length - 1] by 1
			structure = @objectList[i]
			if structure.node == node
				structure.ui.remove()
				@objectList.splice(i, 1)

				if @objectList.length > 0
					@_objectSelect @objectList[@objectList.length - 1]
				return

	selectNode: (node) =>
		# overrides the node selection, maintains the same selected brush
		for s in @objectList
			if s.node == node
				selectedBrush = @selectedStructure.selectedBrush

				@_objectSelect s

				if selectedBrush
					@_brushSelect selectedBrush,
					@selectedStructure.brushjQueryObjects[selectedBrush.text],
					@selectedStructure

				return

	_createBrushUi: (brushjQueryString) =>
		@_selectedBrush = null

		container = $(brushjQueryString)

		for brush in @_brushList
			if not brush.iconBrush
				obj = @_createBrush brush
				container.append obj
				brush.jqueryObject = obj

	_createUi: (structure) =>
		name = structure.node.fileName

		html = "<li class='objectListItem'><p>#{name}</p>
			<div class='objectIconContainer iconFloatRight'></div></li>"
		structure.ui = $(html)

		structure.iconContainer = structure.ui.find('.objectIconContainer')
		structure.iconContainer.hide()
		
		structure.ui.on 'click', () =>
			@_objectSelect(structure)

		structure.brushjQueryObjects = {}
		for brush in @_brushList
			if brush.iconBrush
				@_createIconBrush brush, structure

		objVisHtml = '<span><span class="glyphicon glyphicon-eye-open"></span></span>'
		objVis = $(objVisHtml)
		objVis.on 'click', () =>
			structure.nodeVisible = !structure.nodeVisible
			@_toggleVisibleIcon structure.nodeVisible, objVis
			@_setNodeVisibility structure.nodeVisible, structure.node

		structure.iconContainer.append objVis
		structure.nodeVisible = true


	_createBrush: (brush) =>
		# creates a default brush with list entry
		string = "<div class='btn btn-default brushtext'>#{brush.text}</div>"

		htmlElement = $(string)
		tooltipElement = htmlElement.find('.brushtext')

		@_createTooltip tooltipElement, brush, 'right'

		if brush.canToggleVisibility
			brush.visible = true
			visibilityString = '<div class="iconFloatRight">
				<span class="glyphicon glyphicon-eye-open"></span></div>'
			e = $(visibilityString)
			htmlElement.append e
			e.on 'click', () =>
				@_toggleBrushVisibility brush, e

			e.tooltip {
				title: 'Toggle layer visibility'
				placement: 'right'
				delay: 500
			}

		htmlElement.on 'click', () =>
			@_brushSelect brush

		return htmlElement

	_createIconBrush: (brush, structure) =>
		# creates a brush that is only shown as a icon next to the object
		html = "<span class='glyphicon glyphicon-#{brush.glyphicon}'></span>"
		obj = $(html)
		@_createTooltip obj, brush

		obj.on 'click', () =>
			@_brushSelect brush

		structure.iconContainer.append obj
		brush.jqueryObject = obj

	_createTooltip: (jqueryObject, brush, placement = 'top') =>
		if brush.tooltip?.length > 0
			jqueryObject.tooltip {
				title: brush.tooltip
				delay: 500
				placement: placement
			}

	_objectSelect: (structure) =>
		# Don't do anything when clicking on selected object
		if structure == @selectedStructure
			return

		# deselect previously selected object
		if @selectedStructure?
			@deselectCallback @selectedStructure.node
			@selectedStructure.ui.removeClass('selectedObject')
			@selectedStructure.iconContainer.hide()
			@_deselectBrush @selectedStructure.node

		# select current object
		@selectedStructure = structure
		@selectCallback @selectedStructure.node
		@selectedStructure.ui.addClass('selectedObject')
		@selectedStructure.iconContainer.show()

	_brushSelect: (brush) =>
		# deselect currently selected brush
		if @_selectedBrush?
			if @_selectedBrush.deselectCallback?
				@_selectedBrush.deselectCallback @selectedStructure.node

			@_selectedBrush.jqueryObject.removeClass 'selectedBrush'

		#select new brush
		@_selectedBrush = brush

		brush.jqueryObject.addClass 'selectedBrush'
		if brush.selectCallback?
				brush.selectCallback @selectedStructure.node

	_deselectBrush: (node) =>
		if @_selectedBrush?
			if @_selectedBrush.deselectCallback?
				@_selectedBrush.deselectCallback node

			@_selectedBrush.jqueryObject.removeClass 'selectedBrush'

		@_selectedBrush = null

	_toggleBrushVisibility: (brush, jqueryObject) =>
		brush.visible  = !brush.visible

		@_toggleVisibleIcon brush.visible, jqueryObject

		if brush.visibilityCallback?
			brush.visibilityCallback brush.visible

	_toggleVisibleIcon: (isVisible, jqueryObject) =>
		if isVisible
			jqueryObject.find('.glyphicon').removeClass('glyphicon-eye-close')
			jqueryObject.find('.glyphicon').addClass('glyphicon-eye-open')
		else
			jqueryObject.find('.glyphicon').addClass('glyphicon-eye-close')
			jqueryObject.find('.glyphicon').removeClass('glyphicon-eye-open')

	_setNodeVisibility: (isVisible, node) =>
		solidRenderer = @bundle.getPlugin('solid-renderer')
		solidRenderer.toggleNodeVisibility node, isVisible

	getSelectedBrush: () =>
		return @_selectedBrush
