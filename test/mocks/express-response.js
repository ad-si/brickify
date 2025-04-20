export default class Response {
  constructor () {
    this.status = this.status.bind(this)
    this.location = this.location.bind(this)
    this.whenSent = new Promise((resolve, reject) => {
      return this.setContent = type => {
        return content => {
          this.content = content
          this.type = type
          return resolve()
        }
      }
    })
  }

  status (code) {
    this.code = code
    return {
      json: this.setContent("json"),
      send: this.setContent("text"),
    }
  }

  location (location) {
    this.location = location
    return this
  }
}
