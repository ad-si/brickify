import chai from "chai"
import chaiAsPromised from "chai-as-promised"

import DataPacketsMock from "../mocks/dataPacketsMock.js"
import SyncObject from "../../src/common/sync/syncObject.js"
import Project from "../../src/common/project/project.js"

// Extend chai assertion interface to include custom methods
declare global {
  namespace Chai {
    interface Assertion {
      resolve: Assertion;
    }
  }
}

chai.use(chaiAsPromised)
const { expect } = chai
let dataPackets: DataPacketsMock | null = null

describe("Project tests", () => {
  beforeEach(() => {
    dataPackets = new DataPacketsMock()
    return SyncObject.dataPacketProvider = dataPackets
  })

  return describe("Project creation", () => {
    it("should resolve after creation", () => {
      dataPackets!.nextIds.push("abcdefgh")
      const project = new Project()
      return expect(project.done()).to.resolve
    })

    it("should be a Project and a SyncObject", () => {
      dataPackets!.nextIds.push("abcdefgh")
      const project = new Project()
      return project.done(() => {
        expect(project).to.be.an.instanceof(Project)
        return expect(project).to.be.an.instanceof(SyncObject)
      })
    })

    return it("should have one scene that is active", () => {
      dataPackets!.nextIds.push("abcdefgh")
      const project = new Project()
      return project.done(() => {
        expect(project).to.have.property("scenes")
          .that.is.an("array").with.length(1)
        return expect(project).to.have.deep.property("scenes.active")
          .that.equals(project.scenes[0])
      })
    })
  })
})
