objectTree = require '../common/state/objectTree'

module.exports = class UiObjects
	constructor: (@ui) ->
		@objectList = []
		@selectedStructure = null

	init: (jqueryString) =>
		@jqueryObject = $(jqueryString)
		@selectCallback = @ui.sceneManager.select
		@deselectCallback = @ui.sceneManager.deselect

	onNodeAdd: (node) =>
		# Called by sceneManager when a node is added
		structure = {
			node: node
		}

		@_createUi(structure)

		@objectList.push structure
		@jqueryObject.append structure.ui

		@_select structure


	onNodeRemove: (node) =>
		# Called by sceneManager when a node is removed
		for i in [0..@objectList.length - 1] by 1
			structure = @objectList[i]
			if structure.node == node
				structure.ui.remove()
				@objectList.splice(i, 1)

				if @objectList.length > 0
					@_select @objectList[@objectList.length - 1]
				return

	_createUi: (structure) =>
		name = structure.node.fileName

		html = "<li class='objectListItem'><p>#{name}</p>
			<div class='objectIconContainer'></div><ul class='layerlist'></ul></li>"
		structure.ui = $(html)
		structure.iconContainer = structure.ui.find('.objectIconContainer')
		structure.iconContainer.hide()
		structure.iconContainer.append(
			$('<span class="glyphicon glyphicon-eye-open"></span>')
			)
		structure.iconContainer.append(
			$('<span class="glyphicon glyphicon-move"></span>')
			)
		structure.iconContainer.append(
			$('<span class="glyphicon glyphicon-refresh"></span>')
			)
		
		structure.ui.on 'click', () =>
			@_select(structure)

	_select: (structure) =>
		# Don't do anything when clicking on selected object
		if structure == @selectedStructure
			return

		# deselect previously selected object
		if @selectedStructure?
			@deselectCallback @selectedStructure.node
			@selectedStructure.ui.removeClass('selectedObject')
			@selectedStructure.iconContainer.hide()

		# select current object
		@selectedStructure = structure
		@selectCallback @selectedStructure.node
		@selectedStructure.ui.addClass('selectedObject')
		@selectedStructure.iconContainer.show()


