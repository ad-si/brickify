/*
 * The combined client-side local data packet provider and cache.
 *
 * @module clientDataPackets
 */

import cache from "./dataPacketsCache.js"
import proxy from "./dataPacketsProxy.js"

module.exports.create = () => proxy.create()
  .then(cache.create)

module.exports.exists = id => cache.exists(id)
  .catch(proxy.exists)

module.exports.get = id => cache.get(id)
  .catch(() => proxy.get(id)
    .then(cache.cache))

module.exports.put = packet => proxy.put(packet)
  .then(proxyResult => cache.cache(packet)
    .then(() => proxyResult))

module.exports.delete = id => proxy.delete(id)
  .then(proxyResult => cache.ensureDelete(id)
    .then(() => proxyResult))

module.exports.clear = () => cache.clear()
