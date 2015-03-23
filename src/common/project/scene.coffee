SyncObject = require '../sync/syncObject'
Node = require './node'

###
# A scene is a collection of nodes and settings and represents a state of a
# project.
#
# @class Scene
###
class Scene extends SyncObject
	constructor: ->
		super arguments[0]
		@nodes = []
		@_modify 'Scene creation'

	_modify: (cause) =>
		@lastModified =
			date: Date.now()
			cause: cause

	_loadSubObjects: =>
		_loadNode = (reference) -> Node.from reference
		return Promise.all(@nodes.map _loadNode).then (nodes) => @nodes = nodes

	addNode: (node) =>
		_addNode = =>
			node.getName().then (name) =>
				@nodes.push node
				@_modify "Node \"#{name}\" added"
		return @next _addNode

	getNodes: =>
		return @done => @nodes

	removeNode: (node) =>
		_removeNode = =>
			node.getName().then (name) =>
				if -1 isnt index = @nodes.indexOf node
					@nodes.splice index, 1
					@_modify "Node \"#{name}\" removed"
		return @next _removeNode

module.exports = Scene
