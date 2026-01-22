import SyncObject, { SyncObjectParams } from "../sync/syncObject.js"
import Scene from "./scene.js"

interface ScenesArray extends Array<Scene> {
  active: Scene;
}

/*
 * A project is the root node of a synchronization. It holds at least one
 * (active) scene and might have references to several other old scenes as well.
 *
 * @class Project
 */
export default class Project extends SyncObject {
  static load (): Promise<Project> {
    // TODO: Load from share or session
    return Promise.resolve(new Project())
  }

  declare scenes: ScenesArray

  constructor (param?: SyncObjectParams) {
    super(param)
    this.scenes = [] as unknown as ScenesArray
    this.scenes.active = new Scene()
    this.scenes.push(this.scenes.active)
    // Suppress unhandled rejection warnings while preserving error propagation.
    // The promise will be properly handled when Project.done() is called.
    void this.scenes.active.ready.catch(() => undefined)
  }

  getScene (): Promise<Scene | undefined> {
    return this.done(() => this.scenes.active)
  }
}
