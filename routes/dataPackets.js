import * as dpStorage from "../src/server/sync/dataPacketRamStorage.js"

export function create (_request, response) {
  return dpStorage.create()
    .then(packet => response
      .location("/datapacket/" + packet.id)
      .status(201)
      .json(packet))
    .catch(() => response.status(500)
      .send("Packet could not be created"))
}

export function exists (request, response) {
  return dpStorage.isSaneId(request.params.id)
    .then(() => dpStorage.exists(request.params.id)
      .then(id => response.status(200)
        .send(id))
      .catch(id => response.status(404)
        .send(id)))
    .catch(() => response.status(400)
      .send("Invalid data packet id provided"))
}

export function get (request, response) {
  return dpStorage.isSaneId(request.params.id)
    .then(() => dpStorage.get(request.params.id)
      .then(packet => response.status(200)
        .json(packet))
      .catch(id => response.status(404)
        .send(id)))
    .catch(() => response.status(400)
      .send("Invalid data packet id provided"))
}

export function put (request, response) {
  return dpStorage.isSaneId(request.params.id)
    .then(() => dpStorage.put({id: request.params.id, data: request.body})
      .then(id => response.status(200)
        .send(id))
      .catch(id => response.status(404)
        .send(id)))
    .catch(() => response.status(400)
      .send("Invalid data packet id provided"))
}

export function delete_ (request, response) {
  return dpStorage.isSaneId(request.params.id)
    .then(() => dpStorage.delete_(request.params.id)
      .then(() => response.status(204)
        .send())
      .catch(id => response.status(404)
        .send(id)))
    .catch(() => response.status(400)
      .send("Invalid data packet id provided"))
}

/*
 * Use this only for testing!
 */
export function clear () {
  return dpStorage.clear()
}
