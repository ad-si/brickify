/*
 * Static/offline data packet proxy that uses localStorage instead of server
 *
 * @module clientDataPacketsProxyStatic
 */

const STORAGE_KEY = 'brickify_datapackets'

function generateId() {
  return 'dp_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
}

function getStorage() {
  try {
    const data = localStorage.getItem(STORAGE_KEY)
    return data ? JSON.parse(data) : {}
  } catch {
    return {}
  }
}

function saveStorage(packets) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(packets))
  } catch {
    // localStorage may be full or unavailable
  }
}

export const create = () => {
  const id = generateId()
  const packet = { id, data: {} }
  const packets = getStorage()
  packets[id] = packet
  saveStorage(packets)
  return Promise.resolve(packet)
}

export const exists = id => {
  const packets = getStorage()
  if (packets[id]) {
    return Promise.resolve(id)
  }
  return Promise.reject({ status: 404, statusText: 'Not Found', responseText: id })
}

export const get = id => {
  const packets = getStorage()
  if (packets[id]) {
    return Promise.resolve(packets[id])
  }
  return Promise.reject({ status: 404, statusText: 'Not Found', responseText: id })
}

export const put = packet => {
  const packets = getStorage()
  if (packets[packet.id]) {
    packets[packet.id] = packet
    saveStorage(packets)
    return Promise.resolve(packet.id)
  }
  return Promise.reject({ status: 404, statusText: 'Not Found', responseText: packet.id })
}

export const delete_ = id => {
  const packets = getStorage()
  if (packets[id]) {
    delete packets[id]
    saveStorage(packets)
    return Promise.resolve()
  }
  return Promise.reject({ status: 404, statusText: 'Not Found', responseText: id })
}
