SyncObject = require '../sync/syncObject'

###
# A node is an element in a scene that represents a model.
#
# @class Node
###
class Node extends SyncObject
	constructor: ({name, modelHash, transform} = {}) ->
		super arguments[0]
		@transientProperties = []
		@name = name || null
		@modelHash = modelHash || null
		@transform = {}
		@_setTransform transform

	_isTransient: (key) =>
		return key in @transientProperties or super(key)

	getPluginData: (key) =>
		return @done => @[key]

	storePluginData: (key, data, transient = true) =>
		return @next =>
			@[key] = data
			if transient and key not in @transientProperties
				@transientProperties.push key

	setModelHash: (hash) =>
		return @next => @modelHash = hash

	getModelHash: =>
		return @done => @modelHash

	getModel: =>
		return @done => Node.modelProvider.request @modelHash

	setName: (name) =>
		return @next => @name = name

	getName: =>
		_getName = =>
			if @name?
				return @name
			else
				return "Node #{@id}"
		return @done _getName

	setPosition: (position) =>
		return @setTransform position: position

	getPosition: =>
		return @done => @transform.position

	setRotation: (rotation) =>
		return @setTransform rotation: rotation

	getRotation: =>
		return @done => @transform.rotation

	setScale: (scale) =>
		return @setTransform scale: scale

	getScale: =>
		return @done => @transform.scale

	setTransform: ({position, rotation, scale} = {}) =>
		args = arguments
		return @next => @_setTransform args...

	getTransform: =>
		return @done => @transform

	_setTransform: ({position, rotation, scale} = {}) =>
		@transform.position = position || @transform.position || {x: 0, y: 0, z: 0}
		@transform.rotation = rotation || @transform.rotation || {x: 0, y: 0, z: 0}
		@transform.scale = scale || @transform.scale || {x: 1, y: 1, z: 1}

	@modelProvider = null

module.exports = Node
