/*
 * The client's data packet proxy that interacts with the server
 *
 * @module clientDataPacketsProxy
 */
import $ from "jquery"
import type { DataPacket } from "../../common/sync/syncObject"

interface JqXHRError {
  status: number;
  statusText: string;
  responseText: string;
}

const sanitizeJqXHRError = (jqXHR: JQuery.jqXHR): Promise<never> => Promise.reject({
  status: jqXHR.status,
  statusText: jqXHR.statusText,
  responseText: jqXHR.responseText,
} as JqXHRError)

export const create = (): Promise<DataPacket> => Promise.resolve($.ajax("/datapacket", {type: "POST"}))
  .catch(sanitizeJqXHRError)

export const exists = (id: string): Promise<string> => Promise.resolve($.ajax("/datapacket/" + id, {type: "HEAD"}))
  .then(() => id)
  .catch(sanitizeJqXHRError)

export const get = (id: string): Promise<DataPacket> => Promise.resolve($.ajax("/datapacket/" + id, {type: "GET"}))
  .catch(sanitizeJqXHRError)

export const put = (packet: DataPacket): Promise<void> => Promise.resolve(
  $.ajax("/datapacket/" + packet.id, {
    type: "PUT",
    contentType: "application/json",
    data: JSON.stringify(packet.data),
  }),
)
  .catch(sanitizeJqXHRError)

export const delete_ = (id: string): Promise<void> => Promise.resolve($.ajax("/datapacket/" + id, {type: "DELETE"}))
  .catch(sanitizeJqXHRError)
