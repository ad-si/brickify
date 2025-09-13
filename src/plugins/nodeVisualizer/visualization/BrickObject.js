import THREE from "three"
import DisposableResource from "../../../client/rendering/DisposableResource.js"

/*
 * @class BrickObject
 */
export default class BrickObject extends THREE.Object3D {
  constructor (geometries, materials, fidelity) {
    super()
    this.setBrick = this.setBrick.bind(this)
    this.getBrick = this.getBrick.bind(this)
    this.setMaterial = this.setMaterial.bind(this)
    this.setGray = this.setGray.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
    this.setStudVisibility = this.setStudVisibility.bind(this)
    this._updateStuds = this._updateStuds.bind(this)
    this.dispose = this.dispose.bind(this)
    
    // Initialize disposable resource tracking
    this.disposableResource = new DisposableResource()
    
    this.materials = materials
    const {
      brickGeometry,
      studGeometry,
      highFiStudGeometry,
      planeGeometry,
    } = geometries

    this.areStudsVisible = true

    // Create meshes and track them for disposal
    const brickMesh = this.disposableResource.track(new THREE.Mesh(brickGeometry, this.materials.color))
    const studMesh = this.disposableResource.track(new THREE.Mesh(studGeometry, this.materials.colorStuds))
    const highFiStudMesh = this.disposableResource.track(new THREE.Mesh(highFiStudGeometry, this.materials.colorStuds))
    const planeMesh = this.disposableResource.track(new THREE.Mesh(planeGeometry, this.materials.textureStuds))

    this.add(brickMesh)
    this.add(studMesh)
    this.add(highFiStudMesh)
    this.add(planeMesh)

    this.setFidelity(fidelity)
  }

  setBrick (brick) {
    this.brick = brick
  }
  getBrick () {
    return this.brick
  }
  setMaterial (materials) {
    this.materials = materials
    this.children[0].material = this.materials.color
    this.children[1].material = this.materials.colorStuds
    return this.children[2].material = this.materials.colorStuds
  }

  setGray (isGray) {
    if (isGray) {
      this.children[0].material = this.materials.gray
      this.children[1].material = this.materials.grayStuds
      return this.children[2].material = this.materials.grayStuds
    }
    else {
      this.children[0].material = this.materials.color
      this.children[1].material = this.materials.colorStuds
      return this.children[2].material = this.materials.colorStuds
    }
  }

  setFidelity (fidelity) {
    this.fidelity = fidelity
    return this._updateStuds()
  }

  setStudVisibility (areStudsVisible) {
    this.areStudsVisible = areStudsVisible
    return this._updateStuds()
  }

  _updateStuds () {
    this.children[1].visible = (this.fidelity === 1) && this.areStudsVisible
    this.children[2].visible = (this.fidelity === 2) && this.areStudsVisible
    return this.children[3].visible = (this.fidelity === 0) && this.areStudsVisible
  }

  dispose() {
    if (this.disposableResource && !this.disposableResource.isDisposed()) {
      // Remove from parent first
      if (this.parent) {
        this.parent.remove(this)
      }
      
      // Dispose all tracked resources
      this.disposableResource.dispose()
      this.disposableResource = null
      
      // Clear references
      this.materials = null
      this.brick = null
    }
  }
}
