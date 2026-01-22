import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"

import * as dataPackets from "../../src/client/sync/dataPackets"
import * as proxy from "../../src/client/sync/dataPacketsProxy"

// Mock the proxy module
vi.mock("../../src/client/sync/dataPacketsProxy")

const mockedProxy = vi.mocked(proxy)

describe("dataPacket client cache", () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(async () => {
    await dataPackets.clear()
  })

  describe("dataPacket creation", () => {
    it("should call the server to create a dataPacket", async () => {
      const newPacket = {id: "abcdefgh", data: {}}
      mockedProxy.create.mockResolvedValue(newPacket)

      await dataPackets.create()

      expect(mockedProxy.create).toHaveBeenCalledTimes(1)
    })

    it("should cache a newly created dataPacket", async () => {
      const newPacket = {id: "abcdefgh", data: {}}
      mockedProxy.create.mockResolvedValue(newPacket)

      await dataPackets.create()
      // The second get should not call proxy.get because the packet is cached
      const packet = await dataPackets.get(newPacket.id)

      expect(packet).toEqual(newPacket)
      expect(mockedProxy.create).toHaveBeenCalledTimes(1)
      expect(mockedProxy.get).not.toHaveBeenCalled()
    })

    it("should fail if the server cannot create a dataPacket", async () => {
      const error = { status: 500, statusText: "Internal Server Error", responseText: "Packet could not be created" }
      mockedProxy.create.mockRejectedValue(error)

      await expect(dataPackets.create()).rejects.toHaveProperty("status", 500)
      expect(mockedProxy.create).toHaveBeenCalledTimes(1)
    })
  })

  describe("dataPacket existence checks", () => {
    it("should fail with a malformed id", async () => {
      const error = { status: 400, statusText: "Bad Request", responseText: "Invalid data packet id provided" }
      mockedProxy.exists.mockRejectedValue(error)

      const id = "äöü"
      await expect(dataPackets.exists(id)).rejects.toHaveProperty("status", 400)
      expect(mockedProxy.exists).toHaveBeenCalledTimes(1)
    })

    it("should check with the server about unknown dataPackets", async () => {
      const id = "abcdefgh"
      mockedProxy.exists.mockResolvedValue(id)

      await dataPackets.exists(id)

      expect(mockedProxy.exists).toHaveBeenCalledTimes(1)
      expect(mockedProxy.exists).toHaveBeenCalledWith(id)
    })

    it("should answer from cache if dataPacket is known", async () => {
      const newPacket = {id: "abcdefgh", data: {}}
      mockedProxy.create.mockResolvedValue(newPacket)

      await dataPackets.create()
      const existenceResult = await dataPackets.exists(newPacket.id)

      expect(existenceResult).toEqual(newPacket.id)
      expect(mockedProxy.create).toHaveBeenCalledTimes(1)
      // exists should NOT be called on the proxy since it's in cache
      expect(mockedProxy.exists).not.toHaveBeenCalled()
    })

    it("should fail if dataPacket does not exist", async () => {
      const id = "abcdefgh"
      const error = { status: 404, statusText: "Not Found", responseText: id }
      mockedProxy.exists.mockRejectedValue(error)

      try {
        await dataPackets.exists(id)
        expect.fail("Should have rejected")
      } catch (err: unknown) {
        expect(err).toHaveProperty("status", 404)
        expect(err).toHaveProperty("responseText", id)
      }
      expect(mockedProxy.exists).toHaveBeenCalledTimes(1)
    })
  })

  describe("dataPacket get requests", () => {
    it("should fail with a malformed id", async () => {
      const error = { status: 400, statusText: "Bad Request", responseText: "Invalid data packet id provided" }
      mockedProxy.get.mockRejectedValue(error)

      const id = "äöü"
      await expect(dataPackets.get(id)).rejects.toHaveProperty("status", 400)
      expect(mockedProxy.get).toHaveBeenCalledTimes(1)
    })

    it("should get unknown dataPackets from the server", async () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      mockedProxy.get.mockResolvedValue(packet)

      const result = await dataPackets.get(packet.id)

      expect(result).toEqual(packet)
      expect(mockedProxy.get).toHaveBeenCalledTimes(1)
      expect(mockedProxy.get).toHaveBeenCalledWith(packet.id)
    })

    it("should cache requested dataPackets", async () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      mockedProxy.get.mockResolvedValue(packet)

      await dataPackets.get(packet.id)
      const result = await dataPackets.get(packet.id)

      expect(result).toEqual(packet)
      // get should only be called once since the second call uses cache
      expect(mockedProxy.get).toHaveBeenCalledTimes(1)
    })

    it("should fail if dataPacket does not exist", async () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const error = { status: 404, statusText: "Not Found", responseText: packet.id }
      mockedProxy.get.mockRejectedValue(error)

      try {
        await dataPackets.get(packet.id)
        expect.fail("Should have rejected")
      } catch (err: unknown) {
        expect(err).toHaveProperty("status", 404)
        expect(err).toHaveProperty("responseText", packet.id)
      }
      expect(mockedProxy.get).toHaveBeenCalledTimes(1)
    })
  })

  describe("dataPacket put requests", () => {
    it("should fail with a malformed id", async () => {
      const error = { status: 400, statusText: "Bad Request", responseText: "Invalid data packet id provided" }
      mockedProxy.put.mockRejectedValue(error)

      const packet = {id: "äöü", data: {a: 0, b: "c"}}
      await expect(dataPackets.put(packet)).rejects.toHaveProperty("status", 400)
      expect(mockedProxy.put).toHaveBeenCalledTimes(1)
    })

    it("should fail if dataPacket does not exist", async () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const error = { status: 404, statusText: "Not Found", responseText: packet.id }
      mockedProxy.put.mockRejectedValue(error)

      try {
        await dataPackets.put(packet)
        expect.fail("Should have rejected")
      } catch (err: unknown) {
        expect(err).toHaveProperty("status", 404)
        expect(err).toHaveProperty("responseText", packet.id)
      }
      expect(mockedProxy.put).toHaveBeenCalledTimes(1)
    })

    it("should put to server", async () => {
      mockedProxy.put.mockResolvedValue(undefined)

      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      await dataPackets.put(packet)

      expect(mockedProxy.put).toHaveBeenCalledTimes(1)
      expect(mockedProxy.put).toHaveBeenCalledWith(packet)
    })

    it("should cache changes", async () => {
      mockedProxy.put.mockResolvedValue(undefined)

      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      await dataPackets.put(packet)
      const result = await dataPackets.get(packet.id)

      expect(result).toEqual(packet)
      // get should not be called on proxy since it's cached
      expect(mockedProxy.get).not.toHaveBeenCalled()
    })
  })

  describe("dataPacket deletion", () => {
    it("should fail with a malformed id", async () => {
      const error = { status: 400, statusText: "Bad Request", responseText: "Invalid data packet id provided" }
      mockedProxy.delete_.mockRejectedValue(error)

      const packet = {id: "äöü", data: {a: 0, b: "c"}}
      await expect(dataPackets.delete_(packet.id)).rejects.toHaveProperty("status", 400)
      expect(mockedProxy.delete_).toHaveBeenCalledTimes(1)
    })

    it("should fail if dataPacket does not exist", async () => {
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      const error = { status: 404, statusText: "Not Found", responseText: packet.id }
      mockedProxy.delete_.mockRejectedValue(error)

      try {
        await dataPackets.delete_(packet.id)
        expect.fail("Should have rejected")
      } catch (err: unknown) {
        expect(err).toHaveProperty("status", 404)
        expect(err).toHaveProperty("responseText", packet.id)
      }
      expect(mockedProxy.delete_).toHaveBeenCalledTimes(1)
    })

    it("should delete dataPackets from server", async () => {
      mockedProxy.delete_.mockResolvedValue(undefined)

      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      await dataPackets.delete_(packet.id)

      expect(mockedProxy.delete_).toHaveBeenCalledTimes(1)
      expect(mockedProxy.delete_).toHaveBeenCalledWith(packet.id)
    })

    it("should not find deleted dataPackets", async () => {
      // First, put a packet
      mockedProxy.put.mockResolvedValue(undefined)
      const packet = {id: "abcdefgh", data: {a: 0, b: "c"}}
      await dataPackets.put(packet)

      // Now delete it
      mockedProxy.delete_.mockResolvedValue(undefined)
      await dataPackets.delete_(packet.id)

      // Now exists should fail (cache is cleared, proxy called)
      const error = { status: 404, statusText: "Not Found", responseText: packet.id }
      mockedProxy.exists.mockRejectedValue(error)

      try {
        await dataPackets.exists(packet.id)
        expect.fail("Should have rejected")
      } catch (err: unknown) {
        expect(err).toHaveProperty("status", 404)
        expect(err).toHaveProperty("responseText", packet.id)
      }
      expect(mockedProxy.delete_).toHaveBeenCalledTimes(1)
      expect(mockedProxy.exists).toHaveBeenCalledTimes(1)
    })
  })
})
