/*
 * The combined client-side local data packet provider and cache.
 *
 * @module clientDataPackets
 */

import * as cache from "./dataPacketsCache.js"
import * as proxy from "./dataPacketsProxy.js"

export const create = () => proxy.create()
  .then(cache.create)

export const exists = id => cache.exists(id)
  .catch(proxy.exists)

export const get = id => cache.get(id)
  .catch(() => proxy.get(id)
    .then(cache.cache))

export const put = packet => proxy.put(packet)
  .then(proxyResult => cache.cache(packet)
    .then(() => proxyResult))

export const delete_ = id => proxy.delete_(id)
  .then(proxyResult => cache.ensureDelete(id)
    .then(() => proxyResult))

export const clear = () => cache.clear()
