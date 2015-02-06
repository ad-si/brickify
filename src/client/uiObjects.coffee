objectTree = require '../common/state/objectTree'

module.exports = class UiObjects
	constructor: (@ui) ->
		@objectList = []
		@selectedStructure = null
		return

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

	onNodeRemove: (node) =>
		# Called by sceneManager when a node is removed
		for structure in @objectList
			if structure.node == node
				structure.ui.remove()

	_createUi: (structure) =>
		name = structure.node.fileName

		html = "<div class='objectListItem'><p>#{name}</p></div>"

		structure.ui = $(html)
		structure.ui.on 'click', () =>
			@_handleObjectClick(structure)

	_handleObjectClick: (structure) =>
		# Don't do anything when clicking on selected object
		if structure == @selectedStructure
			return

		# deselect previously selected object
		if @selectedStructure?
			@deselectCallback @selectedStructure.node
			@selectedStructure.ui.removeClass('selectedObject')

		# select current object
		@selectedStructure = structure
		@selectCallback @selectedStructure.node
		@selectedStructure.ui.addClass('selectedObject')


