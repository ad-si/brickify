###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

jqtree = require 'jqtree'
clone = require 'clone'

module.exports = class SceneGraph
	constructor: () ->
		@state = null
		@uiInitialized = false
		@htmlElements = null

	renderUi: (elements) ->
		$treeContainer = $(elements.sceneGraphContainer)
		idCounter = 1
		treeData = [{
			label: 'Scene',
			id: idCounter,
			children: []
		}]

		writeToObject = (treeNode, node) ->
			treeNode.label = treeNode.title = node.fileName or treeNode.label or ''
			treeNode.id = idCounter++

			if node.children
				treeNode.children = []
				node.children.forEach (subNode, index) ->
					treeNode.children[index] = {}
					writeToObject treeNode.children[index], subNode

		writeToObject(treeData[0], @state.rootNode)
		if $treeContainer.is(':empty')
			$treeContainer.tree {
				autoOpen: 0
				data: treeData
				dragAndDrop: true
				keyboardSupport: false
				useContextMenu: false
				onCreateLi: (node, $li) -> $li.attr('title', node.title)
			}

		else
			$treeContainer.tree 'loadData', treeData

	onStateUpdate: (_state, done) ->
		@state = _state
		if @uiInitialized
			@renderUi @htmlElements
		done()

	initUi: (elements) ->
		@htmlElements = elements
		@uiInitialized = true
		if @state
			@renderUi @htmlElements
