export default class DataPacketsMock {
  constructor () {
    this.create = this.create.bind(this)
    this.exists = this.exists.bind(this)
    this.get = this.get.bind(this)
    this.put = this.put.bind(this)
    this.delete = this.delete.bind(this)
    this.calls = 0
    this.createCalls = []
    this.nextIds = []
    this.existsCalls = []
    this.nextExists = []
    this.getCalls = []
    this.nextGets = []
    this.putCalls = []
    this.nextPuts = []
    this.deleteCalls = []
    this.nextDeletes = []
  }

  create () {
    this.calls++
    const nextId = this.nextIds.shift()
    this.createCalls.push(nextId)
    if (nextId) {
      return Promise.resolve({id: nextId, data: {}})
    }
    else {
      return Promise.reject()
    }
  }

  exists (id) {
    this.calls++
    const nextExist = this.nextExists.shift()
    this.existsCalls.push({id, exists: nextExist})
    if (nextExist) {
      return Promise.resolve(id)
    }
    else {
      return Promise.reject(id)
    }
  }

  get (id) {
    this.calls++
    const nextGet = this.nextGets.shift()
    this.getCalls.push({id, get: nextGet})
    if (nextGet) {
      return Promise.resolve(nextGet)
    }
    else {
      return Promise.reject(id)
    }
  }

  put (packet) {
    this.calls++
    const p = JSON.parse(JSON.stringify(packet))
    const nextPut = this.nextPuts.shift()
    this.putCalls.push({packet: p, put: nextPut})
    if (nextPut) {
      return Promise.resolve(p.id)
    }
    else {
      return Promise.reject(p.id)
    }
  }

  delete (id) {
    this.calls++
    const nextDelete = this.nextDeletes.shift()
    this.deleteCalls.push({id, delete: nextDelete})
    if (nextDelete) {
      return Promise.resolve()
    }
    else {
      return Promise.reject(id)
    }
  }
}
