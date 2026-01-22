export default class Request {
  params: Record<string, string>;
  body: unknown;

  constructor (params: Record<string, string> = {}, body: unknown = "") {
    this.params = params
    this.body = body
  }
}
