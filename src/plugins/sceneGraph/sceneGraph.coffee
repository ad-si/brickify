###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

# Should not be global but workaround for broken jqtree
global.$ = require 'jquery'
jqtree = require 'jqtree'
clone = require 'clone'
objectTree = require '../../common/objectTree'

module.exports = class SceneGraph
	constructor: () ->
		@state = null
		@uiInitialized = false
		@htmlElements = null
		@selectedNode = null

	init: (@bundle) ->
		return

	renderUi: (elements) =>
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
				dragAndDrop: false
				keyboardSupport: false
				useContextMenu: true
				onCreateLi: (node, $li) -> $li.attr('title', node.title)
			}

		if @selectedNode
			$treeContainer.tree 'selectNode', @selected_node

		else
			$treeContainer.tree 'loadData', treeData

	onStateUpdate: (@state, done) =>
		if @uiInitialized
			@renderUi @htmlElements
		done()

	onNodeSelect: (event) =>
		if event.node
			@selectedNode = event.node
			nodeLabel = event.node.name
			# console.log "selected node '#{nodeLabel}'"
			@bundle.pluginUiGenerator.selectNode nodeLabel
		else
			# no node = deselected
			@bundle.pluginUiGenerator.deselectNodes()
			@selectedNode = null

	bindEvents: () ->
		$treeContainer = $(@htmlElements.sceneGraphContainer)
		$treeContainer.bind 'tree.select', @onNodeSelect
		$(document).keydown (event) =>
			if event.keyCode == 46 #Delete
				@deleteObject()

	deleteObject: () ->
		if not @selectedNode
			return

		question = "Really delete #{@selectedNode.name}?"
		if confirm question
			delNode = (state) =>
				objectTree.getNodeByFileName @selectedNode.name, state.rootNode,
					(node) =>
						objectTree.removeNode state.rootNode, node
			@bundle.statesync.performStateAction delNode, true



	initUi: (elements) =>
		@htmlElements = elements
		@bindEvents()
		@uiInitialized = true
		if @state
			@renderUi @htmlElements
