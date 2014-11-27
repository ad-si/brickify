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


#Adds an dataset which can be accessed with the specified key
addPluginData = (node, key, data) ->
	node.pluginData[key] = data
	return data

#The node structure is the base structure for all nodes
class NodeStructure
	constructor: () ->
		@properties = {}
		@pluginData = {}


module.exports = {
	forAllSubnodes: forAllSubnodes
	forAllSubnodeProperties: forAllSubnodeProperties
	addPluginData: addPluginData
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
