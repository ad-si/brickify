/*
 * A simple data packet storage that holds data in memory
 *
 * @module dataPacketRamStorage
 */

import * as idGenerator from "./idGenerator.js"

interface DataPacket {
  id: string
  data: Record<string, unknown>
}

interface PacketsMap {
  [id: string]: DataPacket
}

let packets: PacketsMap = {}

export function create (): Promise<DataPacket> {
  const id = idGenerator.generate((id: string) => packets[id] == null)
  if (id === null) {
    return Promise.reject("Could not generate unique id")
  }
  packets[id] = {
    id,
    data: {},
  }
  return Promise.resolve(packets[id])
}

export function isSaneId (id: string): Promise<string> {
  if (idGenerator.check(id)) {
    return Promise.resolve(id)
  }
  else {
    return Promise.reject(id)
  }
}

export function exists (id: string): Promise<string> {
  if (packets[id] != null) {
    return Promise.resolve(id)
  }
  else {
    return Promise.reject(id)
  }
}

export function get (id: string): Promise<DataPacket> {
  if (packets[id] != null) {
    return Promise.resolve(packets[id])
  }
  else {
    return Promise.reject(id)
  }
}

export function put (packet: DataPacket): Promise<string> {
  if (packets[packet.id] != null) {
    packets[packet.id].data = packet.data
    return Promise.resolve(packet.id)
  }
  else {
    return Promise.reject(packet.id)
  }
}

export function delete_ (id: string): Promise<void> {
  if (packets[id] != null) {
    delete packets[id]
    return Promise.resolve()
  }
  else {
    return Promise.reject(id)
  }
}

export function clear (): Promise<void> {
  packets = {}
  return Promise.resolve()
}
