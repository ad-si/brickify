import chai from "chai"
import chaiAsPromised from "chai-as-promised"

import dataPackets from "../../src/client/sync/dataPackets.js"

chai.use(chaiAsPromised)
const { expect } = chai

window.jQuery = window.$ = require("jquery")


describe("dataPacket client cache", () => {
  beforeEach(() => $.mockjaxSettings.logging = false)

  afterEach(() => {
    dataPackets.clear()
    $.mockjax.clear()
    return $.mockjaxSettings.logging = true
  })

  describe("dataPacket creation", () => {
    it("should call the server to create a dataPacket", () => {
      const newPacket = {id: "abcdefgh", data: {}}
      $.mockjax({
        type: "POST",
        url: "/datapacket",
        status: 201,
        contentType: "application/json",
        responseText: newPacket,
      })
      return dataPackets.create()
        .then((packet) => {
          expect(packet).to.deep.equal(newPacket)
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should cache a newly created dataPacket", () => {
      const newPacket = {id: "abcdefgh", data: {}}
      $.mockjax({
        type: "POST",
        url: "/datapacket",
        status: 201,
        contentType: "application/json",
        responseText: newPacket,
      })
      return dataPackets.create()
        .then(() => dataPackets.get(newPacket.id)
          .then((packet) => {
            expect(packet).to.deep.equal(newPacket)
            expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
            return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
          }))
    })

    return it("should fail if the server cannot create a dataPacket", () => {
      $.mockjax({
        type: "POST",
        url: "/datapacket",
        status: 500,
        responseText: "Packet could not be created",
      })
      const creation = dataPackets.create()
      // Rejected returns the reason which is a thenable ajax response that
      // rejects as well -> we have to use not fulfilled and cannot directly
      // use eventually
      return Promise.all([
        expect(creation).not.to.be.fulfilled,
        creation.catch(error => expect(error).to.have.property("status", 500)),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })
  })

  describe("dataPacket existence checks", () => {
    it("should fail with a malformed id", () => {
      $.mockjax({
        type: "HEAD",
        url: /^\/datapacket\/(.*)$/,
        urlParams: ["id"],
        status: 400,
        responseText: "Invalid data packet id provided",
      })
      const id = "äöü"
      const existence = dataPackets.exists(id)
      return Promise.all([
        expect(existence).not.to.be.fulfilled,
        existence.catch(error => expect(error).to.have.property("status", 400)),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should check with the server about unknown dataPackets", () => {
      $.mockjax({
        type: "HEAD",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 200,
      })
      const id = "abcdefgh"
      return dataPackets.exists(id)
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should answer from cache if dataPacket is known", () => {
      const newPacket = {id: "abcdefgh", data: {}}
      $.mockjax({
        type: "POST",
        url: "/datapacket",
        status: 201,
        contentType: "application/json",
        responseText: newPacket,
      })
      return dataPackets.create()
        .then((packet) => {
          const existence = dataPackets.exists(newPacket.id)
          return Promise.all([
            expect(existence).to.be.fulfilled,
            expect(existence).to.eventually.equal(newPacket.id),
          ])
            .then(() => {
              expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
              return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
            })
        })
    })

    return it("should fail if dataPacket does not exist", () => {
      $.mockjax({
        type: "HEAD",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 404,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const id = "abcdefgh"
      const existence = dataPackets.exists(id)
      return Promise.all([
        expect(existence).not.to.be.fulfilled,
        existence.catch((error) => {
          expect(error).to.have.property("status", 404)
          return expect(error).to.have.property("responseText", id)
        }),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })
  })

  describe("dataPacket get requests", () => {
    it("should fail with a malformed id", () => {
      $.mockjax({
        type: "GET",
        url: /^\/datapacket\/(.*)$/,
        urlParams: ["id"],
        status: 400,
        responseText: "Invalid data packet id provided",
      })
      const id = "äöü"
      const get = dataPackets.get(id)
      return Promise.all([
        expect(get).not.to.be.fulfilled,
        get.catch(error => expect(error).to.have.property("status", 400)),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should get unknown dataPackets from the server", () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      $.mockjax({
        type: "GET",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 200,
        contentType: "application/json",
        responseText: packet,
      })
      const get = dataPackets.get(packet.id)
      return Promise.all([
        expect(get).to.be.fulfilled,
        expect(get).to.become(packet),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should cache requested dataPackets", () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      $.mockjax({
        type: "GET",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 200,
        contentType: "application/json",
        responseText: packet,
      })
      return dataPackets.get(packet.id)
        .then(() => {
          const get = dataPackets.get(packet.id)
          return Promise.all([
            expect(get).to.be.fulfilled,
            expect(get).to.become(packet),
          ])
            .then(() => {
              expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
              return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
            })
        })
    })

    return it("should fail if dataPacket does not exist", () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      $.mockjax({
        type: "GET",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 404,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const get = dataPackets.get(packet.id)
      return Promise.all([
        expect(get).not.to.be.fulfilled,
        get.catch((error) => {
          expect(error).to.have.property("status", 404)
          return expect(error).to.have.property("responseText", packet.id)
        }),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })
  })

  describe("dataPacket put requests", () => {
    it("should fail with a malformed id", () => {
      $.mockjax({
        type: "PUT",
        url: /^\/datapacket\/(.*)$/,
        urlParams: ["id"],
        status: 400,
        responseText: "Invalid data packet id provided",
      })
      const packet = {id: "äöü", data: {a: 0, b: "c"}}
      const put = dataPackets.put(packet)
      return Promise.all([
        expect(put).not.to.be.fulfilled,
        put.catch(error => expect(error).to.have.property("status", 400)),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should fail if dataPacket does not exist", () => {
      $.mockjax({
        type: "PUT",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 404,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const put = dataPackets.put(packet)
      return Promise.all([
        expect(put).not.to.be.fulfilled,
        put.catch((error) => {
          expect(error).to.have.property("status", 404)
          return expect(error).to.have.property("responseText", packet.id)
        }),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should put to server", () => {
      $.mockjax({
        type: "PUT",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 200,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const put = dataPackets.put(packet)
      return Promise.all([
        expect(put).to.be.fulfilled,
        expect(put).to.become(packet.id),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    return it("should cache changes", () => {
      $.mockjax({
        type: "PUT",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 200,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      return dataPackets.put(packet)
        .then(() => {
          const get = dataPackets.get(packet.id)
          return Promise.all([
            expect(get).to.be.fulfilled,
            expect(get).to.become(packet),
          ])
            .then(() => {
              expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
              return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
            })
        })
    })
  })

  return describe("dataPacket deletion", () => {
    it("should fail with a malformed id", () => {
      $.mockjax({
        type: "DELETE",
        url: /^\/datapacket\/(.*)$/,
        urlParams: ["id"],
        status: 400,
        responseText: "Invalid data packet id provided",
      })
      const packet = {id: "äöü", data: {a: 0, b: "c"}}
      const del = dataPackets.delete(packet.id)
      return Promise.all([
        expect(del).not.to.be.fulfilled,
        del.catch(error => expect(error).to.have.property("status", 400)),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should fail if dataPacket does not exist", () => {
      $.mockjax({
        type: "DELETE",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 404,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const del = dataPackets.delete(packet.id)
      return Promise.all([
        expect(del).not.to.be.fulfilled,
        del.catch((error) => {
          expect(error).to.have.property("status", 404)
          return expect(error).to.have.property("responseText", packet.id)
        }),
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    it("should delete dataPackets from server", () => {
      $.mockjax({
        type: "DELETE",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 204,
        responseText: "",
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const del = dataPackets.delete(packet.id)
      return Promise.all([
        expect(del).to.be.fulfilled,
        expect(del).to.eventually.be.empty,
      ])
        .then(() => {
          expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
          return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
        })
    })

    return it("should not find deleted dataPackets", function () {
      this.timeout(4000)
      $.mockjax({
        type: "DELETE",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 204,
        responseText: "",
      })
      $.mockjax({
        type: "HEAD",
        url: /^\/datapacket\/([a-zA-Z0-9]+)$/,
        urlParams: ["id"],
        status: 404,
        response (settings) {
          return this.responseText = settings.urlParams.id
        },
      })
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      return dataPackets.delete(packet.id)
        .then(() => {
          const existence = dataPackets.exists(packet.id)
          return Promise.all([
            expect(existence).not.to.be.fulfilled,
            existence.catch((error) => {
              expect(error).to.have.property("status", 404)
              return expect(error).to.have.property("responseText", packet.id)
            }),
          ])
            .then(() => {
              expect($.mockjax.mockedAjaxCalls()).to.have.length(2)
              return expect($.mockjax.unmockedAjaxCalls()).to.be.empty
            })
        })
    })
  })
})
