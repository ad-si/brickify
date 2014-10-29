module.exports.init = (state) ->
	state.rootNode = {}
	initNode(state.rootNode)
	return state.rootNode

module.exports.addChildNode = (node) ->
	newNode = {}
	initNode(newNode)
	node.childNodes.push(newNode)
	return newNode

initNode = (node) ->
		node.childNodes = []
		node.properties = {}
		node.modelData = {}
		node.pluginData = {}