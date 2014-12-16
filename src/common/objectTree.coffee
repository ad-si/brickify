# Executes callback(child) for all subnodes
forAllSubnodes = (node, callback, recursive = true) ->
	if Array.isArray(node.children)
		for child in node.children
			callback child
			if recursive
				forAllSubnodes child, callback, recursive


# Executes callback(childPluginData) for all subnodes
# that have a pluginData entry matching to key
forAllSubnodeProperties = (node, key, callback, recursive = true) ->
	forAllSubnodes node, (child) ->
		if child.pluginData[key]?
			callback (child.pluginData[key])
		if recursive
			forAllSubnodeProperties child, key, callback, recursive

# Executes callback(child) for all subnodes
# that have a pluginData entry matching to key
forAllSubnodesWithProperty = (node, key, callback, recursive = true) ->
	forAllSubnodes node, (child) ->
		if child.pluginData[key]?
			callback (child)
		if recursive
			forAllSubnodesWithProperty child, key, callback, recursive

#Adds an dataset which can be accessed with the specified key
addPluginData = (node, key, data) ->
	node.pluginData[key] = data
	return data

# Finds a node with the given file name. For 'Scene', the root node is returned
getNodeByFileName = (modelName, rootNode, callback) ->
	checkname = (node) ->
		if node.fileName == modelName
			callback node

	if modelName == 'Scene'
		callback rootNode
		return

	forAllSubnodes(rootNode,checkname, callback)

#The node structure is the base structure for all nodes
class NodeStructure
	constructor: () ->
		# DO NOT use as identifier
		@fileName = ''
		# DO use as identifier
		@meshHash = ''
		@positionData =
			position: {x: 0, y: 0, z: 0}
			rotation: {_x: 0, _y: 0, _z: 0}
			scale: {x: 1, y: 1, z: 1}
		@pluginData = {}

module.exports = {
	forAllSubnodes: forAllSubnodes
	forAllSubnodeProperties: forAllSubnodeProperties
	forAllSubnodesWithProperty: forAllSubnodesWithProperty
	addPluginData: addPluginData
	getNodeByFileName: getNodeByFileName
	NodeStructure: NodeStructure

	init: (state) ->
		if not state.objectTreeInitialized
			state.rootNode = new NodeStructure()
			state.objectTreeInitialized = true
			return state.rootNode

	addChild: (node) ->
		newNode = new NodeStructure()

		if(!node.children)
			node.children = []

		node.children.push(newNode)

		return newNode
}
