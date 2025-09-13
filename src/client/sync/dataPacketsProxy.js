/*
 * The client's data packet proxy that interacts with the server
 *
 * @module clientDataPacketsProxy
 */
import $ from "jquery"

const sanitizeJqXHRError = jqXHR => Promise.reject({
  status: jqXHR.status,
  statusText: jqXHR.statusText,
  responseText: jqXHR.responseText,
})

export const create = () => Promise.resolve($.ajax("/datapacket", {type: "POST"}))
  .catch(sanitizeJqXHRError)

export const exists = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "HEAD"}))
  .catch(sanitizeJqXHRError)

export const get = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "GET"}))
  .catch(sanitizeJqXHRError)

export const put = packet => Promise.resolve(
  $.ajax("/datapacket/" + packet.id, {type: "PUT"}, {
    contentType: "application/json",
    data: JSON.stringify(packet.data),
  }),
)
  .catch(sanitizeJqXHRError)

export const delete_ = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "DELETE"}))
  .catch(sanitizeJqXHRError)
