# Executes callback(child) for all subnodes
forAllSubnodes = (node, callback, recursive = true) ->
	_results = []
	if Array.isArray(node.children)
		for child in node.children
			_results.push(callback child)
			if recursive
				_results.push.apply _results, forAllSubnodes(child, callback, recursive)
	return _results

# Executes callback(childPluginData) for all subnodes
# that have a pluginData entry matching to key
forAllSubnodeProperties = (node, key, callback, recursive = true) ->
	propertyCallback = (child) ->
		callback(child.pluginData[key]) if child.pluginData[key]?
	forAllSubnodes node, propertyCallback, recursive


# Executes callback(child) for all subnodes
# that have a pluginData entry matching to key
forAllSubnodesWithProperty = (node, key, callback, recursive = true) ->
	propertyCallback = (child) ->
		callback(child) if child.pluginData[key]?
	forAllSubnodes node, propertyCallback, recursive

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

removeNode = (rootNode, nodeToBeDeleted) ->
	if Array.isArray(rootNode.children)
		for i in [0..rootNode.children.length] by 1
			if rootNode.children[i] == nodeToBeDeleted
				rootNode.children.splice i,1
				return true

		for c in rootNode.children
			if removeNode c, nodeToBeDeleted
				return true
	return false

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
	removeNode: removeNode
	NodeStructure: NodeStructure

	init: (state) ->
		return state.rootNode ?= new NodeStructure()

	addChild: (node) ->
		newNode = new NodeStructure()

		if(!node.children)
			node.children = []

		node.children.push(newNode)

		return newNode
}
