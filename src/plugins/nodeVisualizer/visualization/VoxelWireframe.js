import THREE from "three"

import VoxelUnion from "../../csg/VoxelUnion.js"
import * as interactionHelper from "../../../client/interactionHelper.js"


// This class creates a wireframe representation with darkened sides
// of a given set of voxels
export default class VoxelOutline {
  constructor (bundle, grid, threeNode, coloring) {
    this.setVisibility = this.setVisibility.bind(this)
    this.isVisible = this.isVisible.bind(this)
    this.createWireframe = this.createWireframe.bind(this)
    this.intersectRay = this.intersectRay.bind(this)
    this.bundle = bundle
    this.grid = grid
    this.coloring = coloring
    this.threeNode = new THREE.Object3D()
    threeNode.add(this.threeNode)

    this.voxelUnion = new VoxelUnion(this.grid)
  }

  setVisibility (isVisible) {
    return this.threeNode.visible = isVisible
  }

  isVisible () {
    return this.threeNode.visible
  }

  // creates a wireframe out of voxels
  // @param {Array} voxels array of voxels {x, y, z}[] to create
  // wireframe for
  createWireframe (voxels) {
    // clear old representations
    this.threeNode.children = []

    // create Geometry
    const options = {
      threeBoxGeometryOnly: true,
    }
    const boxGeometry = this.voxelUnion.run(voxels, options)

    // add black sides to make volume more visible
    const shadowBox = new THREE.Mesh(boxGeometry, this.coloring.legoShadowMat)
    this.threeNode.add(shadowBox)
    this.threeNode.shadowBox = shadowBox

    // add black lines to create a visible outline
    // material is not used, but needs to be provided
    const material = new THREE.MeshLambertMaterial({
      color: 0x000000,
    })
    const mesh = new THREE.Mesh(boxGeometry, material)

    const edgeHelper = new THREE.EdgesHelper(mesh, 0x000000, 10)
    edgeHelper.material.linewidth = 2
    this.threeNode.add(edgeHelper)
    return this.threeNode.edgeHelper = edgeHelper
  }

  // returns the intersections between a ray and the shadowBox geometry
  intersectRay (event) {
    const intersectObject = this.threeNode.shadowBox

    // set two sided material to catch all intersections
    const oldMaterialSide = intersectObject.material.side
    intersectObject.material.side = THREE.DoubleSide

    // intersect with ray
    const intersects =
      interactionHelper.getIntersections(
        event,
        this.bundle.renderer,
        [intersectObject],
      )

    // apply old material side property
    intersectObject.material.side = oldMaterialSide

    return intersects
  }
}
