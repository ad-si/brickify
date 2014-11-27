###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

common = require '../../../common/pluginCommon'
jqtree = require 'jqtree'
clone = require 'clone'
state = null
uiInitialized = false
htmlElements = null

renderUi = (elements) ->

	$treeContainer = $(elements.sceneGraphContainer)
	idCounter = 1
	treeData = [{
		label: 'Scene',
		id: idCounter,
		children: []
	}]

	writeToObject = (treeNode, node) ->

		treeNode.label = treeNode.title = node
			.pluginData['stlImport']?.fileName or treeNode.label or ''
		treeNode.id = idCounter++

		if node.children
			treeNode.children = []
			node.children.forEach (subNode, index) ->
				treeNode.children[index] = {}
				writeToObject treeNode.children[index], subNode

	writeToObject(treeData[0], state.rootNode)

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


module.exports.pluginName = 'Scene Graph'
module.exports.category = common.CATEGORY_RENDERER

# Store the global configuration for later use by init3d
module.exports.init = (globalConfig, state, ui) ->
	@globalConfig = globalConfig

module.exports.updateState = (delta, _state) ->
	state = _state
	if uiInitialized
		renderUi htmlElements

module.exports.onUiInit = (elements) ->
	htmlElements = elements
	uiInitialized = true
	if state
		renderUi htmlElements
