/*
 * The client's data packet cache
 *
 * @module clientDataPacketsCache
 */

// A map of promises that resolve to the respective packet or reject with its id
let packets = {}

// cache is the big brother of put: it will always store the packet and resolve
module.exports.cache = packet => packets[packet.id] = Promise.resolve(packet)
const {
  cache,
} = module.exports

// ensureDelete is the big brother of delete: it will delete the packet if
// present and always resolve
module.exports.ensureDelete = function (id) {
  delete packets[id]
  return Promise.resolve()
}
const {
  ensureDelete,
} = module.exports

module.exports.create = packet => cache(packet)

module.exports.exists = function (id) {
  if (packets[id] == null) {
    packets[id] = Promise.reject(id)
  }
  return packets[id].then(() => id)
}
const {
  exists,
} = module.exports

module.exports.get = id => packets[id] != null ? packets[id] : packets[id] = Promise.reject(id)

module.exports.put = packet => exists(packet.id)
  .then(() => cache(packet))
  .then(Promise.resolve(packet.id))

module.exports.delete = function (id) {
  if (packets[id] != null) {
    return ensureDelete(id)
  }
  else {
    return Promise.reject(id)
  }
}

module.exports.clear = function () {
  packets = {}
  return Promise.resolve()
}
