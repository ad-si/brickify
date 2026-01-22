import type { Request, Response } from "express"
import * as dpStorage from "../src/server/sync/dataPacketRamStorage.js"

export function create (_request: Request, response: Response) {
  return dpStorage.create()
    .then(packet => response
      .location("/datapacket/" + packet.id)
      .status(201)
      .json(packet))
    .catch(() => response.status(500)
      .send("Packet could not be created"))
}

export function exists (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.exists(id)
      .then(resultId => response.status(200)
        .send(resultId))
      .catch((resultId: unknown) => {
        const message = (resultId as any)?.message ?? String(resultId)
        return response.status(404).send(message)
      }))
    .catch((error: unknown) => {
      const message = (error as any)?.message ?? String(error)
      return response.status(400).send(message)
    })
}

export function get (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.get(id)
      .then(packet => response.status(200)
        .json(packet))
      .catch((resultId: unknown) => {
        const message = (resultId as any)?.message ?? String(resultId)
        return response.status(404).send(message)
      }))
    .catch((error: unknown) => {
      const message = (error as any)?.message ?? String(error)
      return response.status(400).send(message)
    })
}

export function put (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.put({id, data: request.body})
      .then(() => response.status(200)
        .send(id))
      .catch((resultId: unknown) => {
        const message = (resultId as any)?.message ?? String(resultId)
        return response.status(404).send(message)
      }))
    .catch((error: unknown) => {
      const message = (error as any)?.message ?? String(error)
      return response.status(400).send(message)
    })
}

export function delete_ (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.delete_(id)
      .then(() => response.status(204)
        .send())
      .catch((resultId: unknown) => {
        const message = (resultId as any)?.message ?? String(resultId)
        return response.status(404).send(message)
      }))
    .catch((error: unknown) => {
      const message = (error as any)?.message ?? String(error)
      return response.status(400).send(message)
    })
}

/*
 * Use this only for testing!
 */
export function clear () {
  return dpStorage.clear()
}
