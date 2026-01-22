export default class Response {
  whenSent: Promise<void>;
  content: unknown;
  type: string;
  code: number;
  private setContent: (type: string) => (content: unknown) => void;

  constructor () {
    this.content = undefined
    this.type = ""
    this.code = 0
    this.setContent = () => () => {}

    this.status = this.status.bind(this)
    this.whenSent = new Promise<void>((resolve) => {
      this.setContent = (type: string) => {
        return (content: unknown) => {
          this.content = content
          this.type = type
          resolve()
        }
      }
    })
  }

  status (code: number) {
    this.code = code
    return {
      json: this.setContent("json"),
      send: this.setContent("text"),
    }
  }

  location (_location: string) {
    return this
  }
}
