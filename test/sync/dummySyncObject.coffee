SyncObject = require '../../src/common/sync/syncObject'

class Dummy extends SyncObject
	constructor: ->
		super arguments[0]
		@dummyProperty = 'a'
		@dummyTransient = 'transient'

	dummyMethod: ->
		return 'b'

	@dummyClassMethod: ->
		return 'd'

	@dummyClassProperty: 'e'

	_isTransient: (key) ->
		return key is 'dummyTransient' || super key

module.exports = Dummy
