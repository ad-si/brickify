###
# #SyncObject
# This is a helper super class for objects that are synchronized using
# dataPackets.
# @class SyncObject
###
class SyncObject
	###
	# ##Instance creation and synchronization
	###

	@dataPacketProvider: null

	###
	# Constructs a new SyncObject
	#
	# Due to the synchronization process there are restrictions to the constructors
	# of subclasses: All parameters must be passed as 'named parameters', meaning
	# as an object. The key _generateId must not be used. The constructor must
	# call SyncObject's constructor by calling super(arguments[0]).
	###
	constructor: ({_generateId} = {}) ->
		if _generateId || not _generateId?
			@ready = SyncObject.dataPacketProvider.create()
			.then (packet) => @id = packet.id
		else
			@ready = Promise.resolve()

	###
	# Wraps a given plain old javascript object in a new object constructed
	# from the respective subclass of SyncObject
	#
	# @param {Object} packet a data packet
	# @return {SyncObject} a object of the respective subclass that holds all
	# the properties data had as well.
	# @memberOf SyncObject
	###
	@newFrom: (packet) ->
		return new @(_generateId: false).next (syncObject) ->
			syncObject[p] = packet.data[p] for own p of packet.data
			syncObject.id = packet.id

	getId: =>
		return @id

	###
	# Checks whether the property with the given key should be synchronized or
	# ignored. All functions will be ignored automatically.
	# This function can be overwritten by subclasses to ignore additional
	# properties, but the subclass has to call super(key)!
	#
	# @param {String} the name of the property to be checked.
	# @return {Boolean} true if the key should be ignored
	# @memberOf SyncObject
	###
	_isTransient: (key) ->
		return -1 isnt ['id', 'ready', '_packet'].indexOf key

	###
	# Builds an object that only consists of non-transient plain objects.
	# Is used for JSON.stringify() and the synchronization.
	###
	toJSON: =>
		pojso = {} # plain old javascript object
		keys = Object.keys @
		.filter (key) => typeof @[key] isnt 'function' && not @_isTransient(key)
		.map (key) => pojso[key] = @[key]
		return pojso

	_getPacket: =>
		return @_packet ?= {id: @getId(), data: @.toJSON()}

	###
	# Saves any non-transient data of this object to the server.
	###
	save: =>
		@ready = @ready.then => SyncObject.dataPacketProvider.put @_getPacket()
		return @ready

	###
	# Deletes the object from the server.
	# Caution: after calling delete() on a SyncObject, it will be more or less
	# unusable, because next, done, save and delete will reject all further calls.
	###
	delete: =>
		@ready = @ready.then => SyncObject.dataPacketProvider.delete @getId()
		@ready.then => @ready = Promise.reject(
			new ReferenceError("#{@.constructor.name} \##{@getId()} was deleted")
		)
		return @ready

	###
	# ##Asynchronous task chaining
	# A syncObject implements a access point to chain asynchronous tasks via
	# promises.
	###

	###
	# Chains up a new asynchronous task that is run after all previous tasks
	# have completed. Both arguments are optional.
	#
	# @param {Function} onFulfilled run when previous task fulfilled with @
	# @param {Function} onRejected run when previous task rejected with its reason
	# @return {SyncObject} this
	# @memberOf SyncObject
	###
	next: (onFulfilled, onRejected) =>
		@done onFulfilled, onRejected
		return @

	###
	# Chains up a new asynchronous task that is run after all previous tasks
	# have completed. Both arguments are optional.
	#
	# @param {Function} onFulfilled run when previous task fulfilled with @
	# @param {Function} onRejected run when previous task rejected with its reason
	# @return {Promise} resolves or rejects according to the run callback's result
	# @memberOf SyncObject
	###
	done: (onFulfilled, onRejected) =>
		# we don't want to pass return values from a previous then but pass @
		onFulfilledThis = => onFulfilled? @
		return @ready = @ready.then onFulfilledThis, onRejected

	###
	# Chains up a new error handler.
	# This is only syntactic sugar for done(undefined, onRejected)
	# @param {Function} onFulfilled run when previous task fulfilled with @
	# @param {Function} onRejected run when previous task rejected with its reason
	# @memberOf SyncObject
	###
	catch: (onRejected) =>
		return @ready = @ready.catch onRejected

module.exports = SyncObject
