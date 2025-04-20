import clone from "clone"
import chai from "chai"
import chaiAsPromised from "chai-as-promised"
import chaiShallowDeepEqual from "chai-shallow-deep-equal"

import DataPacketsMock from "../mocks/dataPacketsMock.js"
import SyncObject from "../../src/common/sync/syncObject.js"
import Dummy from "./dummySyncObject.js"


chai.use(chaiAsPromised)
chai.use(chaiShallowDeepEqual)
const { expect } = chai

let dataPackets = null

describe("SyncObject tests", () => {
  beforeEach(() => {
    dataPackets = new DataPacketsMock()
    return SyncObject.dataPacketProvider = dataPackets
  })

  describe("SyncObject creation", () => {
    it("should resolve after creation", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return expect(dummy.done()).to.resolve
    })

    it("should be a Dummy and a SyncObject", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return dummy.done(() => {
        expect(dummy).to.be.an.instanceof(Dummy)
        return expect(dummy).to.be.an.instanceof(SyncObject)
      })
    })

    it("should get an id by dataPacketProvider", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return dummy.done(() => {
        expect(dummy).to.have.property("id", nextId)
        expect(dataPackets.calls).to.equal(1)
        return expect(dataPackets.createCalls).to.deep.equal([nextId])
      })
    })

    it("should support creation from a packet", () => {
      const pojso = {a: "b", c: {d: "e"}}
      const packet = {id: "abcdefgh", data: pojso}
      const request = Dummy.from(packet)
      expect(request).to.resolve
      return request.then((dummy) => {
        expect(dataPackets.calls).to.equal(0)
        return dummy.done(() => {
          expect(dummy).to.be.an.instanceof(Dummy)
          expect(dummy).to.be.an.instanceof(SyncObject)
          return expect(dummy).to.shallowDeepEqual(pojso)
        })
      })
    })

    it("should support loading from many packets", () => {
      let j
      let i
      const pojsos = []
      const packets = []

      for (j = 0, i = j; j <= 2; j++, i = j) {
        pojsos[i] = {a: "b" + i, c: {d: "e" + i}}
        packets[i] = {id: "abcdefgh" + i, data: pojsos[i]}
      }

      const requests = Promise.all(Dummy.from(packets))
      expect(requests).to.resolve
      return requests.then((dummies) => {
        expect(dummies).to.have.length(packets.length)
        const promises = dummies.map(dummy => dummy.done())
        return Promise.all(promises)
          .then(() => {
            expect(dataPackets.calls).to.equal(0)
            return (() => {
              let end
              const result = []
              for (i = 0, end = dummies.length; i < end; i++) {
                const dummy = dummies[i]
                expect(dummy).to.be.an.instanceof(Dummy)
                expect(dummy).to.be.an.instanceof(SyncObject)
                result.push(expect(dummy).to.shallowDeepEqual(pojsos[i]))
              }
              return result
            })()
          })
      })
    })

    it("should support loading from an id", () => {
      const pojso = {a: "b", c: {d: "e"}}
      const id = "abcdefgh"
      const packet = {id, data: pojso}
      dataPackets.nextGets.push(packet)
      const request = Dummy.from(id)
      expect(request).to.resolve
      return request.then(dummy => dummy.done(() => {
        expect(dataPackets.calls).to.equal(1)
        expect(dataPackets.getCalls).to.have.length(1)
        expect(dummy).to.be.an.instanceof(Dummy)
        expect(dummy).to.be.an.instanceof(SyncObject)
        return expect(dummy).to.shallowDeepEqual(pojso)
      }))
    })

    it("should support loading from many ids", () => {
      let j
      let i
      const pojsos = []
      const ids = []
      const packets = []

      for (j = 0, i = j; j <= 2; j++, i = j) {
        pojsos[i] = {a: "b" + i, c: {d: "e" + i}}
        ids[i] = "abcdefgh" + i
        packets[i] = {id: ids[i], data: pojsos[i]}
        dataPackets.nextGets.push(packets[i])
      }

      const requests = Promise.all(Dummy.from(ids))
      expect(requests).to.resolve
      return requests.then((dummies) => {
        expect(dummies).to.have.length(ids.length)
        expect(dataPackets.calls).to.equal(ids.length)
        expect(dataPackets.getCalls).to.have.length(ids.length)
        const promises = dummies.map(dummy => dummy.done())
        return Promise.all(promises)
          .then(() => (() => {
            let end
            const result = []
            for (i = 0, end = dummies.length; i < end; i++) {
              const dummy = dummies[i]
              expect(dummy).to.be.an.instanceof(Dummy)
              expect(dummy).to.be.an.instanceof(SyncObject)
              result.push(expect(dummy).to.shallowDeepEqual(pojsos[i]))
            }
            return result
          })())
      })
    })

    it("should support loading from a reference", () => {
      const pojso = {a: "b", c: {d: "e"}}
      const id = "abcdefgh"
      const packet = {id, data: pojso}
      dataPackets.nextGets.push(packet)
      const request = Dummy.from({dataPacketRef: id})
      expect(request).to.resolve
      return request.then(dummy => dummy.done(() => {
        expect(dataPackets.calls).to.equal(1)
        expect(dataPackets.getCalls).to.have.length(1)
        expect(dummy).to.be.an.instanceof(Dummy)
        expect(dummy).to.be.an.instanceof(SyncObject)
        return expect(dummy).to.shallowDeepEqual(pojso)
      }))
    })

    return it("should support loading from many references", () => {
      let j
      let i
      const pojsos = []
      const ids = []
      const references = []
      const packets = []

      for (j = 0, i = j; j <= 2; j++, i = j) {
        pojsos[i] = {a: "b" + i, c: {d: "e" + i}}
        ids[i] = "abcdefgh" + i
        references[i] = {dataPacketRef: ids[i]}
        packets[i] = {id: ids[i], data: pojsos[i]}
        dataPackets.nextGets.push(packets[i])
      }

      const requests = Promise.all(Dummy.from(references))
      expect(requests).to.resolve
      return requests.then((dummies) => {
        expect(dummies).to.have.length(references.length)
        expect(dataPackets.calls).to.equal(references.length)
        expect(dataPackets.getCalls).to.have.length(references.length)
        const promises = dummies.map(dummy => dummy.done())
        return Promise.all(promises)
          .then(() => (() => {
            let end
            const result = []
            for (i = 0, end = dummies.length; i < end; i++) {
              const dummy = dummies[i]
              expect(dummy).to.be.an.instanceof(Dummy)
              expect(dummy).to.be.an.instanceof(SyncObject)
              result.push(expect(dummy).to.shallowDeepEqual(pojsos[i]))
            }
            return result
          })())
      })
    })
  })

  describe("SyncObject synchronization", () => {
    it("should be stringified to a reference", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return dummy.done(() => {
        const string = JSON.stringify(dummy)
        return expect(string).to.equal(`{\"dataPacketRef\":\"${nextId}\"}`)
      })
    })

    it("should save a correct dataPacket", () => {
      dataPackets.nextPuts.push(true)
      const pojso = {a: "b", c: {d: "e"}}
      const packet = {id: "abcdefgh", data: pojso}
      const expected = clone(packet)
      expected.data.dummyProperty = "a"
      const request = Dummy.from(packet)
      return request.then(dummy => dummy.save()
        .then(() => {
          expect(dataPackets.calls).to.equal(1)
          expect(dataPackets.putCalls)
            .to.deep.have.property("[0].packet").deep.equal(expected)
          return expect(dataPackets.putCalls).to.deep.have.property("[0].put", true)
        }))
    })

    it("should save newly added properties", () => {
      dataPackets.nextPuts.push(true)
      dataPackets.nextPuts.push(true)
      const pojso = {a: "b", c: {d: "e"}}
      const packet = {id: "abcdefgh", data: pojso}
      const expected = clone(packet)
      expected.data.dummyProperty = "a"
      const request = Dummy.from(packet)
      return request.then(dummy => dummy.save()
        .then(() => {
          dummy.newProperty = "b"
          expected.data.newProperty = "b"
          return dummy.save()
            .then(() => {
              expect(dataPackets.calls).to.equal(2)
              expect(dataPackets.putCalls)
                .to.deep.have.property("[1].packet").deep.equal(expected)
              return expect(dataPackets.putCalls).to.deep.have.property("[0].put", true)
            })
        }))
    })

    it("should delete the right datapacket", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      dataPackets.nextDeletes.push(true)
      const dummy = new Dummy()
      return dummy.delete()
        .then(() => {
          expect(dataPackets.calls).to.equal(2)
          expect(dataPackets.createCalls).to.deep.equal([nextId])
          return expect(dataPackets.deleteCalls)
            .to.deep.equal([{delete: true, id: nextId}])
        })
    })

    return it("should reject after deletion", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      dataPackets.nextDeletes.push(true)
      const dummy = new Dummy()
      return dummy.delete()
        .then(() => expect(dummy.done()).to.be.rejectedWith(`Dummy \#${nextId} was deleted`))
    })
  })

  return describe("Task chaining", () => {
    it("should return itself when calling next", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return expect(dummy.next()).to.equal(dummy)
    })

    it("should return a promise when calling done", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      return expect(dummy.done()).to.be.an.instanceof(Promise)
    })

    it("should resolve the done promise to the result of the callback", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      const result = {a: "b"}
      return expect(dummy.done( () => result)).to.eventually.equal(result)
    })

    it("should reject the done promise to thrown errors of the callback", () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      const error = "Something bad happened"
      return expect(dummy.done( () => {
        throw new Error(error)
      })).to.be.rejectedWith(error)
    })

    return it("should catch previous errors",  () => {
      let nextId
      dataPackets.nextIds.push(nextId = "abcdefgh")
      const dummy = new Dummy()
      const error = "Something bad happened"
      const result = {a: "b"}
      return expect(dummy.done( () => {
        throw new Error(error)
      })
        .catch( () => result))
        .to.eventually.equal(result)
    })
  })
})
