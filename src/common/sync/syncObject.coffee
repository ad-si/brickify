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
	# Builds the respective subclass of SyncObject from a descriptor or a
	# descriptor array which can either be a packet with an id and a data plain
	# old javascript object or an array of packets or an id of a packet to load or
	# an array of packet ids to be loaded or a DataPacket reference or an array
	# of DataPacket references.
	#
	# @param {String|Array<String>|Object|Array<Object>} syncObjectDescriptor
	# @return {SyncObject|Array<SyncObject>} as Promise or Array of Promises
	# @promise
	# @memberOf SyncObject
	###
	@from: (syncObjectDescriptor) ->
		_syncObjectFromPacket = (packet) =>
			new @(_generateId: false).next (syncObject) ->
				syncObject[p] = packet.data[p] for own p of packet.data
				syncObject.id = packet.id
				syncObject._loadSubObjects()

		_packetFromId = (id) => SyncObject.dataPacketProvider.get id

		_fromOne = (descriptor) =>
			if typeof descriptor is 'string'
				packet = _packetFromId descriptor
			else if @isSyncObjectReference descriptor
				packet = _packetFromId descriptor.id
			else if @isDataPacket descriptor
				packet = Promise.resolve descriptor
			else
				throw new Error descriptor + ' is not an id, a packet or a reference.'

			return packet.then _syncObjectFromPacket

		if Array.isArray syncObjectDescriptor
			return syncObjectDescriptor.map _fromOne
		else
			return _fromOne syncObjectDescriptor

	###
	# This method is called by @from after all properties of a restored SyncObject
	# are loaded, but without resolving children that are references to
	# DataPackets. A subclass that has such children should implement
	# loadSubObjects to resolve those references and load the respective
	# SyncObjects if they should be accessible after initialization.
	###
	_loadSubObjects: ->
		return

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

	@isSyncObjectReference: (pojso) ->
		return typeof pojso.dataPacketRef is 'string'

	@isDataPacket: (pojso) ->
		return typeof pojso.id is 'string' and pojso.data?

	###
	# Builds an object that only consists of non-transient plain objects.
	# (Also called "Plain Old JavaScript Object")
	# @return {Object} key/value mapping of this object's non-transient properties
	###
	toPOJSO: =>
		pojso = {}
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
