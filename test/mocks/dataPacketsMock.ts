import type { DataPacket } from "../../src/common/sync/syncObject.js"

interface ExistsCall {
  id: string;
  exists: boolean | undefined;
}

interface GetCall {
  id: string;
  get: DataPacket | undefined;
}

interface PutCall {
  packet: DataPacket;
  put: boolean | undefined;
}

interface DeleteCall {
  id: string;
  delete: boolean | undefined;
}

export default class DataPacketsMock {
  calls: number;
  createCalls: string[];
  nextIds: string[];
  existsCalls: ExistsCall[];
  nextExists: boolean[];
  getCalls: GetCall[];
  nextGets: DataPacket[];
  putCalls: PutCall[];
  nextPuts: boolean[];
  deleteCalls: DeleteCall[];
  nextDeletes: boolean[];

  constructor () {
    this.create = this.create.bind(this)
    this.exists = this.exists.bind(this)
    this.get = this.get.bind(this)
    this.put = this.put.bind(this)
    this.delete_ = this.delete_.bind(this)
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

  create (): Promise<DataPacket> {
    this.calls++
    const nextId = this.nextIds.shift()
    this.createCalls.push(nextId as string)
    if (nextId) {
      return Promise.resolve({id: nextId, data: {}})
    }
    else {
      return Promise.reject()
    }
  }

  exists (id: string): Promise<string> {
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

  get (id: string): Promise<DataPacket> {
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

  put (packet: DataPacket): Promise<void> {
    this.calls++
    const p = JSON.parse(JSON.stringify(packet)) as DataPacket
    const nextPut = this.nextPuts.shift()
    this.putCalls.push({packet: p, put: nextPut})
    if (nextPut) {
      return Promise.resolve()
    }
    else {
      return Promise.reject(p.id)
    }
  }

  delete_ (id: string): Promise<void> {
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
