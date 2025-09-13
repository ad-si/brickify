/*
 * The client's data packet cache
 *
 * @module clientDataPacketsCache
 */

// A map of promises that resolve to the respective packet or reject with its id
let packets = {}

// cache is the big brother of put: it will always store the packet and resolve
export const cache = packet => packets[packet.id] = Promise.resolve(packet)

// ensureDelete is the big brother of delete: it will delete the packet if
// present and always resolve
export const ensureDelete = function (id) {
  delete packets[id]
  return Promise.resolve()
}

export const create = packet => cache(packet)

export const exists = function (id) {
  if (packets[id] == null) {
    packets[id] = Promise.reject(id)
  }
  return packets[id].then(() => id)
}

export const get = id => packets[id] != null ? packets[id] : packets[id] = Promise.reject(id)

export const put = packet => exists(packet.id)
  .then(() => cache(packet))
  .then(Promise.resolve(packet.id))

export const delete_ = function (id) {
  if (packets[id] != null) {
    return ensureDelete(id)
  }
  else {
    return Promise.reject(id)
  }
}

export const clear = function () {
  packets = {}
  return Promise.resolve()
}
