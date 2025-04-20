import chai from "chai"

import * as dataPackets from "../../routes/dataPackets.js"
import Request from "../mocks/express-request.js"
import Response from "../mocks/express-response.js"

const { expect } = chai

describe("server-side dataPacket-storage tests", () => {
  afterEach(() => dataPackets.clear())

  describe("dataPacket creation", () => it("should create empty packets", () => {
    const response = new Response()
    dataPackets.create(new Request(), response)
    return response.whenSent.then(() => {
      expect(response).to.have.property("type", "json")
      expect(response).to.have.property("code", 201)
      expect(response).to.have.deep.property("content.id")
      return expect(response).to.have.deep.property("content.data").to.be.empty
    })
  }))

  describe("dataPacket existence checks", () => {
    it("should reject invalid id exists checks", () => {
      const response = new Response()
      dataPackets.exists(
        new Request({id: "äöü"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        return expect(response).to.have.property("code", 400)
      })
    })

    it("should not find non existing packet", () => {
      const response = new Response()
      const id = "abcdefgh"
      dataPackets.exists(
        new Request({id}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        expect(response).to.have.property("code", 404)
        return expect(response).to.have.property("content", id)
      })
    })

    return it("should find existing packet", () => {
      const createResponse = new Response()
      dataPackets.create(new Request(), createResponse)
      return createResponse.whenSent.then(() => {
        const {
          id,
        } = createResponse.content
        const existsResponse = new Response()
        dataPackets.exists(
          new Request({id}),
          existsResponse,
        )
        return existsResponse.whenSent.then(() => {
          expect(existsResponse).to.have.property("type", "text")
          expect(existsResponse).to.have.property("code", 200)
          return expect(existsResponse).to.have.property("content", id)
        })
      })
    })
  })

  describe("dataPacket get requests", () => {
    it("should reject invalid id gets", () => {
      const response = new Response()
      dataPackets.get(
        new Request({id: "äöü"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        return expect(response).to.have.property("code", 400)
      })
    })

    it("should not get non existing packet", () => {
      const response = new Response()
      dataPackets.get(
        new Request({id: "abcdefgh"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        expect(response).to.have.property("code", 404)
        return expect(response).to.have.property("content", "abcdefgh")
      })
    })

    return it("should return existing packet", () => {
      const createResponse = new Response()
      dataPackets.create(new Request(), createResponse)
      return createResponse.whenSent.then(() => {
        const {
          id,
        } = createResponse.content
        const content = {a: 0, b: "c"}
        const putResponse = new Response()
        dataPackets.put(
          new Request({id}, content),
          putResponse,
        )
        return putResponse.whenSent.then(() => {
          const getResponse = new Response()
          dataPackets.get(
            new Request({id}),
            getResponse,
          )
          return getResponse.whenSent.then(() => {
            expect(getResponse).to.have.property("type", "json")
            expect(getResponse).to.have.property("code", 200)
            expect(getResponse).to.have.deep.property("content.id", id)
            return expect(getResponse).to.have.deep.property("content.data", content)
          })
        })
      })
    })
  })

  describe("dataPacket put requests", () => {
    it("should reject invalid id puts", () => {
      const response = new Response()
      dataPackets.put(
        new Request({id: "äöü"}, {a: 0, b: "c"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        return expect(response).to.have.property("code", 400)
      })
    })

    it("should not put non existing packet", () => {
      const response = new Response()
      dataPackets.put(
        new Request({id: "abcdefgh"}, {a: 0, b: "c"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        expect(response).to.have.property("code", 404)
        return expect(response).to.have.property("content", "abcdefgh")
      })
    })

    return it("should put existing packet", () => {
      const createResponse = new Response()
      dataPackets.create(new Request(), createResponse)
      return createResponse.whenSent.then(() => {
        const {
          id,
        } = createResponse.content
        const content = {a: 0, b: "c"}
        const putResponse = new Response()
        dataPackets.put(
          new Request({id}, content),
          putResponse,
        )
        return putResponse.whenSent.then(() => {
          expect(putResponse).to.have.property("type", "text")
          expect(putResponse).to.have.property("code", 200)
          return expect(putResponse).to.have.property("content", id)
        })
      })
    })
  })

  return describe("dataPacket deletion", () => {
    it("should reject invalid id puts", () => {
      const response = new Response()
      dataPackets.delete_(
        new Request({id: "äöü"}, {a: 0, b: "c"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        return expect(response).to.have.property("code", 400)
      })
    })

    it("should not delete non existing packet", () => {
      const response = new Response()
      dataPackets.delete_(
        new Request({id: "abcdefgh"}, {a: 0, b: "c"}),
        response,
      )
      return response.whenSent.then(() => {
        expect(response).to.have.property("type", "text")
        expect(response).to.have.property("code", 404)
        return expect(response).to.have.property("content", "abcdefgh")
      })
    })

    it("should delete specified packets", () => {
      const createResponse = new Response()
      dataPackets.create(new Request(), createResponse)
      return createResponse.whenSent.then(() => {
        const deleteResponse = new Response()
        dataPackets.delete_(
          new Request({id: createResponse.content.id}),
          deleteResponse,
        )
        return deleteResponse.whenSent.then(() => {
          expect(deleteResponse).to.have.property("type", "text")
          expect(deleteResponse).to.have.property("code", 204)
          return expect(deleteResponse).to.have.property("content").which.is.empty
        })
      })
    })

    return it("should not find deleted packets", () => {
      const createResponse = new Response()
      dataPackets.create(new Request(), createResponse)
      return createResponse.whenSent.then(() => {
        const {
          id,
        } = createResponse.content
        const deleteResponse = new Response()
        dataPackets.delete_(
          new Request({id}),
          deleteResponse,
        )
        return deleteResponse.whenSent.then(() => {
          const existsResponse = new Response()
          dataPackets.exists(
            new Request({id}),
            existsResponse,
          )
          return existsResponse.whenSent.then(() => {
            expect(existsResponse).to.have.property("type", "text")
            expect(existsResponse).to.have.property("code", 404)
            return expect(existsResponse).to.have.property("content", id)
          })
        })
      })
    })
  })
})
