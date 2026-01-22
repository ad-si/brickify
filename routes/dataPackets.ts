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
        return response.status(404).send(resultId)
      }))
    .catch((error: unknown) => {
      return response.status(400).send(error)
    })
}

export function get (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.get(id)
      .then(packet => response.status(200)
        .json(packet))
      .catch((resultId: unknown) => {
        return response.status(404).send(resultId)
      }))
    .catch((error: unknown) => {
      return response.status(400).send(error)
    })
}

export function put (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.put({id, data: request.body as Record<string, unknown>})
      .then(() => response.status(200)
        .send(id))
      .catch((resultId: unknown) => {
        return response.status(404).send(resultId)
      }))
    .catch((error: unknown) => {
      return response.status(400).send(error)
    })
}

export function delete_ (request: Request, response: Response) {
  const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id
  return dpStorage.isSaneId(id)
    .then(() => dpStorage.delete_(id)
      .then(() => response.status(204)
        .send())
      .catch((resultId: unknown) => {
        return response.status(404).send(resultId)
      }))
    .catch((error: unknown) => {
      return response.status(400).send(error)
    })
}

/*
 * Use this only for testing!
 */
export function clear () {
  return dpStorage.clear()
}
