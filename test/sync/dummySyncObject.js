import SyncObject from "../../src/common/sync/syncObject.js"

export default class Dummy extends SyncObject {
  static initClass () {

    this.dummyClassProperty = "e"
  }
  constructor () {
    super(arguments[0])
    this.dummyProperty = "a"
    this.dummyTransient = "transient"
  }

  dummyMethod () {
    return "b"
  }

  static dummyClassMethod () {
    return "d"
  }

  _isTransient (key) {
    return (key === "dummyTransient") || super._isTransient(key)
  }
}
Dummy.initClass()
