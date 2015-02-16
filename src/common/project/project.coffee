SyncObject = require '../sync/syncObject'
Scene = require './scene'

###
# A project is the root node of a synchronization. It holds at least one
# (active) scene and might have references to several other old scenes as well.
#
# @class Project
###
class Project extends SyncObject
	constructor: ->
		super arguments[0]
		@scenes = []
		@scenes.active = new Scene()
		@scenes.push @scenes.active

	getScene: ->
		return @done => @scenes.active

module.exports = Project
