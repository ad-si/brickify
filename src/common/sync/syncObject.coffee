###
# This is a helper super class for objects that are synchronized using
# dataPackets.
# @class SyncObject
###
class SyncObject
	###
	# ##Instance creation and synchronization
	###

	###
	# Static packetProvider injection. Usually this is client/sync/dataPackets
	# or server/sync/dataPacketRamStorage
	###
	@dataPacketProvider: null

	###
	# Constructs a new SyncObject
	#
	# Due to the synchronization process there are restrictions to the constructors
	# of subclasses: All parameters must be passed as 'named parameters', meaning
	# as an object. The constructor must call SyncObject's constructor by calling
	# super(arguments[0]).
	#
	# @param {Object} params the named parameters
	# @param {Boolean} [params._generateId=true] true for a new SyncObject
	# @memberOf SyncObject
	###
	constructor: ({_generateId} = {}) ->
		if _generateId || not _generateId?
			@ready = SyncObject.dataPacketProvider.create()
			.then (packet) => @id = packet.id
		else
			@ready = Promise.resolve()

	###
	# Loads a dataPacket via id and wraps it in a new object constructed
	# from the respective subclass of SyncObject
	#
	# @param {String} dataPacketId the id of the dataPacket to load
	# @return {Promise} resolves to the created object of the respective subclass
	# @memberOf SyncObject
	###
	@load: (dataPacketIds) ->
		getPacketPromise = (id) =>
			SyncObject.dataPacketProvider.get(id).then (packet) => @newFrom packet

		if Array.isArray dataPacketIds
			return dataPacketIds.map getPacketPromise
		else
			return getPacketPromise dataPacketIds

	###
	# Wraps a given plain old javascript object in a new object constructed
	# from the respective subclass of SyncObject
	#
	# @param {Object} packet a data packet
	# @return {SyncObject} object of the respective subclass with added properties
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
	# @param {String} key the name of the property to be checked.
	# @return {Boolean} true if the key should be ignored
	###
	_isTransient: (key) ->
		return -1 isnt ['id', 'ready', '_packet'].indexOf key

	###
	# For JSON serialization of parent objects only write a reference.
	# @return {String} a DataPacket reference to this SyncObject.
	###
	toJSON: =>
		return dataPacketRef: @getId()

	###
	# Builds an object that only consists of non-transient plain objects.
	# @return {Object} key/value mapping of this object's non-transient properties
	###
	toPOJSO: =>
		pojso = {} # plain old javascript object
		keys = Object.keys @
		.filter (key) => typeof @[key] isnt 'function' && not @_isTransient(key)
		.map (key) => pojso[key] = @[key]
		return pojso

	_getPacket: =>
		return @_packet ?= {id: @getId(), data: @toPOJSO()}

	###
	# Saves any non-transient data of this object to the server.
	# @promise
	###
	save: =>
		@ready = @ready.then => SyncObject.dataPacketProvider.put @_getPacket()
		return @ready

	###
	# Deletes the object from the server.
	# Caution: after calling delete() on a SyncObject, it will be more or less
	# unusable, because next, done, save and delete will reject all further calls.
	# @promise
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
	# @return {Object} resolves or rejects according to the run callback's result
	# @promise
	###
	done: (onFulfilled, onRejected) =>
		# we don't want to pass return values from a previous then but pass @
		onFulfilledThis = => onFulfilled? @
		return @ready = @ready.then onFulfilledThis, onRejected

	###
	# Chains up a new error handler.
	# This is only syntactic sugar for done(undefined, onRejected)
	# @param {Function} onRejected run when previous task rejected with its reason
	# @promise
	###
	catch: (onRejected) =>
		return @ready = @ready.catch onRejected

module.exports = SyncObject
