SyncObject = require '../sync/syncObject'

###
# A node is an element in a scene that represents a model.
#
# @class Node
###
class Node extends SyncObject
	constructor: ->
		super arguments[0]
		@modelHash = null
		@name = null

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

	@modelProvider = null

module.exports = Node
