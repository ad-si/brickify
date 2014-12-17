###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

# Should not be global but workaround for broken jqtree
global.$ = require 'jquery'
jqtree = require 'jqtree'
clone = require 'clone'
objectTree = require '../../common/objectTree'
pluginKey = 'SceneGraph'

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
		$treeContainer.empty()
		idCounter = 1
		treeData = [{
			label: 'Scene',
			id: idCounter,
			children: []
		}]

		writeToObject = (treeNode, node) ->
			if node.pluginData[pluginKey]?
				treeNode.id = node.pluginData[pluginKey].linkedId
			else
				treeNode.id = idCounter++
				objectTree.addPluginData node, pluginKey, {linkedId: treeNode.id}

			treeNode.label = treeNode.title = node.fileName or treeNode.label or ''

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

		$treeContainer.tree 'loadData', treeData

		if @selectedNode
			$treeContainer.tree 'selectNode', @selected_node

	onStateUpdate: (@state, done) =>
		if @uiInitialized
			@renderUi @htmlElements
		done()

	onNodeSelect: (event) =>
		if event.node
			if event.node.name == 'Scene'
				@callNodeDeselect()
				return

			@selectedNode = event.node

			@bundle.statesync.performStateAction (state) =>
				@getStateNodeForTreeNode event.node, state.rootNode, (stateNode) =>
					@selectedStateNode = stateNode
					@bundle.pluginUiGenerator.selectNode stateNode

		else
			@callNodeDeselect()

	callNodeDeselect: () ->
		@bundle.pluginUiGenerator.deselectNodes()
		@selectedNode = null
		@selectedStateNode = null

	bindEvents: () ->
		$treeContainer = $(@htmlElements.sceneGraphContainer)
		$treeContainer.bind 'tree.select', @onNodeSelect
		$(document).keydown (event) =>
			if event.keyCode == 46 #Delete
				@deleteObject()

	getStateNodeForTreeNode: (treeNode, stateRootNode, callback) ->
		objectTree.forAllSubnodes stateRootNode, (node) ->
			if node.pluginData[pluginKey]?
				if node.pluginData[pluginKey].linkedId == treeNode.id
					callback node

	deleteObject: () ->
		if not @selectedNode or @selectedNode.name == 'Scene'
			return

		question = "Really delete #{@selectedNode.name}?"
		bootbox.confirm question, (result) =>
			if result
				delNode = (state) =>
						objectTree.removeNode state.rootNode, @selectedStateNode
						@selectedNode = null
						@selectedStateNode = null
						@callNodeDeselect()

				@bundle.statesync.performStateAction delNode, true

	initUi: (elements) =>
		@htmlElements = elements
		@bindEvents()
		@uiInitialized = true
		if @state
			@renderUi @htmlElements
