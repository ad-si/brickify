module.exports.init = (state) ->
	if not state.objectTreeInitialized
		state.rootNode = {}
		initNode(state.rootNode)
		state.objectTreeInitialized = true
		return state.rootNode

module.exports.addChildNode = (node) ->
	newNode = {}
	initNode(newNode)
	node.childNodes.push(newNode)
	return newNode

module.exports.addThreeObjectCoordiates = (node, object) ->
	node.positionData =
		position: object.position
		rotation: object.rotation
		scale: object.scale

forAllSubnodes = (node, callback, recursive = true) ->
	for child in node.childNodes
		callback child
		if recursive
			forAllSubnodes(child, callback)
module.exports.forAllSubnodes = forAllSubnodes

initNode = (node) ->
		node.childNodes = []
		node.properties = {}
		node.positionData = {}
		node.meshHash = ""
		node.threeObjectUuid = ""
		node.pluginData = {}