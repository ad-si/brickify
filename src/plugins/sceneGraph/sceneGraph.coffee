###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

# Should not be global but workaround for broken jqtree
$ = require 'jquery'
jqtree = require 'jqtree'
clone = require 'clone'
objectTree = require '../../common/state/objectTree'
pluginKey = 'SceneGraph'

module.exports = class SceneGraph
	constructor: () ->
		@uiInitialized = false
		@selectedNode = null
		@idCounter = 1

	init: (@bundle) ->
		return

	initUi: (sceneGraphContainer) ->
		@tree = $(sceneGraphContainer)
		@tree.bind 'tree.select', @_onNodeSelect

	renderUi: (state) =>
		return if not @tree?
		treeData = [{
			label: 'Scene',
			id: @idCounter,
			children: []
		}]
		@createTreeDataStructure(treeData[0], state.rootNode)

		if @tree.is(':empty')
			@tree.tree {
				autoOpen: 0
				data: treeData
				dragAndDrop: false
				keyboardSupport: false
				useContextMenu: true
				onCreateLi: (node, $li) ->
					$li.attr('title', node.title)
					$li.attr('id', 'sgn' + node.id)
			}
		@tree.tree 'loadData', treeData

		if @selectedNode
			@tree.tree 'selectNode', @selectedNode
			$('#sgn' + @selectedNode.id).addClass 'jqtree-selected'

	createTreeDataStructure: (treeNode, node) =>
		if node.pluginData[pluginKey]?
			treeNode.id = node.pluginData[pluginKey].linkedId
			# if reloading the state, get highest assigned id to prevent
			# giving objects the same id
			@idCounter = treeNode.id + 1 if treeNode.id >= @idCounter
		else
			treeNode.id = @idCounter++
			objectTree.addPluginData node, pluginKey, {linkedId: treeNode.id}

		treeNode.label = treeNode.title = node.fileName or treeNode.label or ''

		if node.children
			treeNode.children = []
			node.children.forEach (subNode, index) =>
				treeNode.children[index] = {}
				@createTreeDataStructure treeNode.children[index], subNode

	onStateUpdate: (state) =>
		@renderUi state

	_onNodeSelect: (event) =>
		event.stopPropagation()

		if event.node
			if event.node.name == 'Scene'
				@_onNodeDeselect('Scene')
				return

			# console.log "Selecting " + event.node.title
			@selectedNode = event.node

			@bundle.statesync.performStateAction (state) =>
				@getStateNodeForTreeNode event.node, state.rootNode, (stateNode) =>
					@selectedStateNode = stateNode
					@bundle.ui.sceneManager.select stateNode
		else
			@_onNodeDeselect(@selectedNode.name)

	_onNodeDeselect: (title) =>
		@bundle.ui.sceneManager.deselect()

		#definitively deselect any node
		if @tree.tree 'getSelectedNode'
			@tree.tree 'selectNode', null

		# remove selected style from node
		if title
			$(".jqtree_common [title='" + title + "']").removeClass 'jqtree-selected'

		@selectedNode = null
		@selectedStateNode = null

	getStateNodeForTreeNode: (treeNode, stateRootNode, callback) ->
		objectTree.forAllSubnodes stateRootNode, (node) ->
			if node.pluginData[pluginKey]?
				if node.pluginData[pluginKey].linkedId == treeNode.id
					callback node
