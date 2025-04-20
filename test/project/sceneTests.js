import chai from "chai"
import chaiAsPromised from "chai-as-promised"
import chaiShallowDeepEqual from "chai-shallow-deep-equal"

import DataPacketsMock from "../mocks/dataPacketsMock.js"
import SyncObject from "../../src/common/sync/syncObject.js"
import Scene from "../../src/common/project/scene.js"
import Node from "../../src/common/project/node.js"
import sceneChaiHelper from "./sceneChaiHelper.js"

chai.use(sceneChaiHelper)
chai.use(chaiAsPromised)
chai.use(chaiShallowDeepEqual)

const { expect } = chai

let dataPackets = null

describe("Scene tests", () => {
  beforeEach(() => {
    dataPackets = new DataPacketsMock()
    return SyncObject.dataPacketProvider = dataPackets
  })

  describe("Scene creation", () => {
    it("should resolve after creation", () => {
      dataPackets.nextIds.push("abcdefgh")
      const scene = new Scene()
      return expect(scene.done()).to.resolve
    })

    return it("should be a Scene and a SyncObject", () => {
      dataPackets.nextIds.push("abcdefgh")
      const before = Date.now()
      const scene = new Scene()
      return scene.done(() => {
        expect(scene).to.be.an.instanceof(Scene)
        expect(scene).to.be.an.instanceof(SyncObject)
        expect(scene).to.have.property("nodes")
          .that.is.an("array").with.length(0)
        return expect(scene).to.be.modified(Date.now(), Date.now() - before).with
          .cause("Scene creation")
      })
    })
  })

  describe("Scene manipulation", () => {
    it("should accept new nodes", () => {
      dataPackets.nextIds.push("abcdefgh")
      const scene = new Scene()
      dataPackets.nextIds.push("ijklmnop")
      const node = new Node()
      const name = "Beautiful Model"
      node.setName(name)
      const before = Date.now()
      const result = scene.addNode(node)
      expect(result).to.equal(scene)
      return scene.done(() => {
        expect(scene).to.have.property("nodes").that.deep.equals([node])
        return expect(scene).to.be.modified(Date.now(), Date.now() - before).with
          .cause(`Node \"${name}\" added`)
      })
    })

    return it("should remove present nodes", () => {
      dataPackets.nextIds.push("abcdefgh")
      const scene = new Scene()
      dataPackets.nextIds.push("ijklmnop")
      const node = new Node()
      const name = "Beautiful Model"
      node.setName(name)
      const before = Date.now()
      scene.addNode(node)
      const result = scene.removeNode(node)
      expect(result).to.equal(scene)
      return scene.done(() => {
        expect(scene).to.have.property("nodes")
          .that.is.an("array").with.length(0)
        return expect(scene).to.be.modified(Date.now(), Date.now() - before).with
          .cause(`Node \"${name}\" removed`)
      })
    })
  })

  return describe("Scene synchronization", () => {
    it("should store nodes as references", () => {
      let nodeId
      dataPackets.nextIds.push("sceneid")
      const scene = new Scene()
      dataPackets.nextIds.push(nodeId = "nodeid")
      const node = new Node()
      node.setName("Beautiful Model")
      scene.addNode(node)
      dataPackets.nextPuts.push(true)
      scene.save()
      return scene.done(() => {
        const {
          packet,
        } = dataPackets.putCalls[0]
        expect(packet).to.have.deep.property("data.nodes").that.is.an("array")
        const {
          nodes,
        } = packet.data
        expect(nodes).to.have.length(1)
        return expect(nodes[0]).to.deep.equal({dataPacketRef: nodeId})
      })
    })

    return it("should restore node objects from references", () => {
      const scene = {
        id: "sceneid",
        data: {
          nodes: [{dataPacketRef: "nodeid"}],
        },
      }
      dataPackets.nextGets.push(scene)
      const node = {
        id: "nodeid",
        data: { modelIdentifier: "abcdefghijklmnop", name: "Beautiful Model" },
      }
      dataPackets.nextGets.push(node)

      const request = Scene.from("nodeid")
      expect(request).to.resolve
      return request.then(scene => scene.done(() => {
        expect(scene).to.have.property("nodes").that.is.an("array")
        const {
          nodes,
        } = scene
        expect(nodes).to.have.length(1)
        return expect(nodes[0]).to.shallowDeepEqual(node.data)
      }))
    })
  })
})
