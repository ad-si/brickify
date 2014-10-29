module.exports.init = (state) ->
	state.rootNode = {}
	initNode(state.rootNode)
	return state.rootNode

module.exports.addChildNode = (node) ->
	newNode = {}
	initNode(newNode)
	node.childNodes.push(newNode)
	return newNode

module.exports.addThreeObject = (node, object) ->
	node.positionData =
		position: object.position
		rotation: object.rotation
		scale: object.scale
	node.meshData =
		colorAttributes: object.geometry.attributes.color
		normalAttributes: object.geometry.attributes.normal
		positionAttributes: object.geometry.attributes.position


initNode = (node) ->
		node.childNodes = []
		node.properties = {}
		node.positionData = {}
		node.meshData = {}
		node.pluginData = {}