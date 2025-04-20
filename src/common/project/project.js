import SyncObject from "../sync/syncObject.js"
import Scene from "./scene.js"

/*
 * A project is the root node of a synchronization. It holds at least one
 * (active) scene and might have references to several other old scenes as well.
 *
 * @class Project
 */
export default class Project extends SyncObject {
  static initClass () {
    this.load = () => {
      // TODO: Load from share or session
      return Promise.resolve(new this())
    }
  }

  constructor () {
    super(arguments[0])
    this.scenes = []
    this.scenes.active = new Scene()
    this.scenes.push(this.scenes.active)
  }

  getScene () {
    return this.done(() => this.scenes.active)
  }
}
Project.initClass()
