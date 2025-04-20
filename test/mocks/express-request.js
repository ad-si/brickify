export default class Request {
  constructor (params, body) {
    if (params == null) {
      params = {}
    }
    this.params = params
    if (body == null) {
      body = ""
    }
    this.body = body
  }
}
