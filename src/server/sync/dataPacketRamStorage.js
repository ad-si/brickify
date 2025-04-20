/*
 * A simple data packet storage that holds data in memory
 *
 * @module dataPacketRamStorage
 */

import * as idGenerator from "./idGenerator.js"

let packets = {}

export function create () {
  const id = idGenerator.generate(id => packets[id] == null)
  packets[id] = {
    id,
    data: {},
  }
  return Promise.resolve(packets[id])
}

export function isSaneId (id) {
  if (idGenerator.check(id)) {
    return Promise.resolve(id)
  }
  else {
    return Promise.reject(id)
  }
}

export function exists (id) {
  if (packets[id] != null) {
    return Promise.resolve(id)
  }
  else {
    return Promise.reject(id)
  }
}

export function get (id) {
  if (packets[id] != null) {
    return Promise.resolve(packets[id])
  }
  else {
    return Promise.reject(id)
  }
}

export function put (packet) {
  if (packets[packet.id] != null) {
    packets[packet.id].data = packet.data
    return Promise.resolve(packet.id)
  }
  else {
    return Promise.reject(packet.id)
  }
}

export function delete_ (id) {
  if (packets[id] != null) {
    delete packets[id]
    return Promise.resolve()
  }
  else {
    return Promise.reject(id)
  }
}

export function clear () {
  packets = {}
  return Promise.resolve()
}
