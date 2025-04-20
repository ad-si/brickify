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

module.exports.create = () => Promise.resolve($.ajax("/datapacket", {type: "POST"}))
  .catch(sanitizeJqXHRError)

module.exports.exists = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "HEAD"}))
  .catch(sanitizeJqXHRError)

module.exports.get = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "GET"}))
  .catch(sanitizeJqXHRError)

module.exports.put = packet => Promise.resolve(
  $.ajax("/datapacket/" + packet.id, {type: "PUT"}, {
    contentType: "application/json",
    data: JSON.stringify(packet.data),
  }),
)
  .catch(sanitizeJqXHRError)

module.exports.delete = id => Promise.resolve($.ajax("/datapacket/" + id, {type: "DELETE"}))
  .catch(sanitizeJqXHRError)
