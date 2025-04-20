/*
 * This is a helper super class for objects that are synchronized using
 * dataPackets.
 * @class SyncObject
 */
export default class SyncObject {
  static initClass () {
    /*
     * ##Instance creation and synchronization
     */

    /*
     * Static packetProvider injection. Usually this is client/sync/dataPackets
     * or server/sync/dataPacketRamStorage
     */
    this.dataPacketProvider = null
  }

  /*
   * Constructs a new SyncObject
   *
   * Due to the synchronization process there are restrictions to the constructors
   * of subclasses: All parameters must be passed as 'named parameters', meaning
   * as an object. The constructor must call SyncObject's constructor by calling
   * super(arguments[0]).
   *
   * @param {Object} params the named parameters
   * @param {Boolean} [params._generateId=true] true for a new SyncObject
   * @memberOf SyncObject
   */
  constructor (param) {
    this.getId = this.getId.bind(this)
    this.toJSON = this.toJSON.bind(this)
    this.toPOJSO = this.toPOJSO.bind(this)
    this._getPacket = this._getPacket.bind(this)
    this.save = this.save.bind(this)
    this.delete = this.delete.bind(this)
    this.next = this.next.bind(this)
    this.done = this.done.bind(this)
    this.catch = this.catch.bind(this)
    if (param == null) {
      param = {}
    }
    const {_generateId} = param
    if (_generateId || (_generateId == null)) {
      this.ready = SyncObject.dataPacketProvider.create()
        .then(packet => {
          return this.id = packet.id
        })
    }
    else {
      this.ready = Promise.resolve()
    }
  }

  /*
   * Builds the respective subclass of SyncObject from a descriptor or a
   * descriptor array which can either be a packet with an id and a data plain
   * old javascript object or an array of packets or an id of a packet to load or
   * an array of packet ids to be loaded or a DataPacket reference or an array
   * of DataPacket references.
   *
   * @param {String|Array<String>|Object|Array<Object>} syncObjectDescriptor
   * @return {SyncObject|Array<SyncObject>} as Promise or Array of Promises
   * @promise
   * @memberOf SyncObject
   */
  static from (syncObjectDescriptor) {
    const _syncObjectFromPacket = packet => {
      return new this({_generateId: false})
        .next((syncObject) => {
          for (const p of Object.keys(packet.data || {})) {
            syncObject[p] = packet.data[p]
          }
          syncObject.id = packet.id
          return syncObject._loadSubObjects()
        })
    }

    const _packetFromId = id => SyncObject.dataPacketProvider.get(id)

    const _fromOne = descriptor => {
      let packet
      if (typeof descriptor === "string") {
        packet = _packetFromId(descriptor)
      }
      else if (this.isSyncObjectReference(descriptor)) {
        packet = _packetFromId(descriptor.id)
      }
      else if (this.isDataPacket(descriptor)) {
        packet = Promise.resolve(descriptor)
      }
      else {
        throw new Error(descriptor + " is not an id, a packet or a reference.")
      }

      return packet.then(_syncObjectFromPacket)
    }

    if (Array.isArray(syncObjectDescriptor)) {
      return syncObjectDescriptor.map(_fromOne)
    }
    else {
      return _fromOne(syncObjectDescriptor)
    }
  }

  /*
   * This method is called by @from after all properties of a restored SyncObject
   * are loaded, but without resolving children that are references to
   * DataPackets. A subclass that has such children should implement
   * loadSubObjects to resolve those references and load the respective
   * SyncObjects if they should be accessible after initialization.
   */
  _loadSubObjects () {
  }

  getId () {
    return this.id
  }

  /*
   * Checks whether the property with the given key should be synchronized or
   * ignored. All functions will be ignored automatically.
   * This function can be overwritten by subclasses to ignore additional
   * properties, but the subclass has to call super(key)!
   *
   * @param {String} key the name of the property to be checked.
   * @return {Boolean} true if the key should be ignored
   */
  _isTransient (key) {
    return ["id", "ready"].indexOf(key) !== -1
  }

  /*
   * For JSON serialization of parent objects only write a reference.
   * @return {String} a DataPacket reference to this SyncObject.
   */
  toJSON () {
    return {dataPacketRef: this.getId()}
  }

  static isSyncObjectReference (pojso) {
    return typeof pojso.dataPacketRef === "string"
  }

  static isDataPacket (pojso) {
    return (typeof pojso.id === "string") && (pojso.data != null)
  }

  /*
   * Builds an object that only consists of non-transient plain objects.
   * (Also called "Plain Old JavaScript Object")
   * @return {Object} key/value mapping of this object's non-transient properties
   */
  toPOJSO () {
    const pojso = {}
    const keys = Object.keys(this)
      .filter(key => (typeof this[key] !== "function") && !this._isTransient(key))
      .map(key => {
        return pojso[key] = this[key]
      })
    return pojso
  }

  _getPacket () {
    return {id: this.getId(), data: this.toPOJSO()}
  }

  /*
   * Saves any non-transient data of this object to the server.
   * @promise
   */
  save () {
    this.ready = this.ready.then(() => SyncObject.dataPacketProvider.put(this._getPacket()))
    return this.ready
  }

  /*
   * Deletes the object from the server.
   * Caution: after calling delete() on a SyncObject, it will be more or less
   * unusable, because next, done, save and delete will reject all further calls.
   * @promise
   */
  delete () {
    this.ready = this.ready.then(() => SyncObject.dataPacketProvider.delete(this.getId()))
    this.ready.then(() => {
      return this.ready = Promise.reject(
        new ReferenceError(`${this.constructor.name} \#${this.getId()} was deleted`),
      )
    })
    return this.ready
  }

  /*
   * ##Asynchronous task chaining
   * A syncObject implements an access point to chain asynchronous tasks via
   * promises.
   */

  /*
   * Chains up a new asynchronous task that is run after all previous tasks
   * have completed. Both arguments are optional.
   *
   * @param {Function} onFulfilled run when previous task fulfilled with @
   * @param {Function} onRejected run when previous task rejected with its reason
   * @return {SyncObject} this
   */
  next (onFulfilled, onRejected) {
    this.done(onFulfilled, onRejected)
    return this
  }

  /*
   * Chains up a new asynchronous task that is run after all previous tasks
   * have completed. Both arguments are optional.
   *
   * @param {Function} onFulfilled run when previous task fulfilled with @
   * @param {Function} onRejected run when previous task rejected with its reason
   * @return {Object} resolves or rejects according to the run callback's result
   * @promise
   */
  done (onFulfilled, onRejected) {
    // we don't want to pass return values from a previous then but pass @
    const onFulfilledThis = () => typeof onFulfilled === "function" ? onFulfilled(this) : undefined
    return this.ready = this.ready.then(onFulfilledThis, onRejected)
  }

  /*
   * Chains up a new error handler.
   * This is only syntactic sugar for done(undefined, onRejected)
   * @param {Function} onRejected run when previous task rejected with its reason
   * @promise
   */
  catch (onRejected) {
    return this.ready = this.ready.catch(onRejected)
  }
}
SyncObject.initClass()
