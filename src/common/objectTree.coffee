module.exports.init = (state) ->
	if not state.objectTreeInitialized
		state.rootNode = new NodeStructure()
		state.objectTreeInitialized = true
		return state.rootNode

module.exports.addChildNode = (node) ->
	newNode = new NodeStructure()
	node.childNodes.push(newNode)
	return newNode

#Executes callback(childNode) for all subnodes
forAllSubnodes = (node, callback, recursive = true) ->
	for child in node.childNodes
		callback child
		if recursive
			forAllSubnodes child, callback, recursive
module.exports.forAllSubnodes = forAllSubnodes

# Executes callback(childNodePluginData) for all subnodes
# that have a pluginData entry matching to key
forAllSubnodePluginData = (node, key, callback, recursive = true) ->
	forAllSubnodes node, (child) ->
		for pd in child.pluginData
			if pd.key == key
				callback (pd.value)
				break

		if recursive
			forAllSubnodePluginData child, key, callback, recursive
module.exports.forAllSubnodeProperties = forAllSubnodePluginData

#Adds an dataset which can be accessed with the specified key
addPluginData = (node, key, data) ->
	for pd in node.pluginData
		if pd.key == key
			pd.value = data
			return

	newData =
		key: key
		value: data
	node.pluginData.push(newData)

	return newData.value
module.exports.addPluginData = addPluginData

#The node structure is the base structure for all nodes
class NodeStructure
	constructor: () ->
		#A list of child nodes
		@childNodes = []
		@properties = {}
		@pluginData = []
module.exports.NodeStructure = NodeStructure
