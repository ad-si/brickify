module.exports.init = (state) ->
	state.rootNode = {}
	initNode(state.rootNode)
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


initNode = (node) ->
		node.childNodes = []
		node.properties = {}
		node.positionData = {}
		node.meshHash = ""
		node.threeObjectUuid = ""
		node.pluginData = {}