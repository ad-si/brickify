import THREE from "three"
import * as threeHelper from "../../client/threeHelper.js"
import * as threeConverter from "../../client/threeConverter.js"

export default class ModelVisualization {
  constructor (globalConfig, node, threeNode, coloring) {
    this.setSolidMaterial = this.setSolidMaterial.bind(this)
    this.setNodeVisibility = this.setNodeVisibility.bind(this)
    this.setShadowVisibility = this.setShadowVisibility.bind(this)
    this.afterCreation = this.afterCreation.bind(this)
    this.getSolid = this.getSolid.bind(this)
    this._createVisualization = this._createVisualization.bind(this)
    this.globalConfig = globalConfig
    this.node = node
    this.coloring = coloring
    this.threeNode = new THREE.Object3D()
    threeNode.add(this.threeNode)
  }

  createVisualization () {
    return this._createVisualization(this.node)
  }

  setSolidMaterial (material) {
    return this.afterCreationPromise.then(() => {
      return this.threeNode.solid != null ? this.threeNode.solid.material = material : undefined
    })
  }

  setNodeVisibility (visible) {
    return this.afterCreationPromise.then(() => {
      return this.threeNode.visible = visible
    })
  }

  setShadowVisibility (visible) {
    return this.afterCreationPromise.then(() => {
      return this.threeNode.wireframe != null ? this.threeNode.wireframe.visible = visible : undefined
    })
  }

  afterCreation () {
    return this.afterCreationPromise
  }

  getSolid () {
    return this.threeNode.solid
  }

  _createVisualization (node) {

    const _addSolid = (geometry, parent) => {
      const solid = new THREE.Mesh(geometry, this.coloring.objectPrintMaterial)
      parent.add(solid)
      return parent.solid = solid
    }

    const _addWireframe = (geometry, parent) => {
      const wireframe = new THREE.Object3D()

      // shadow
      const shadow = new THREE.Mesh(geometry, this.coloring.objectShadowMat)
      wireframe.add(shadow)

      // visible black lines
      const lineObject = new THREE.Mesh(geometry)
      const lines = new THREE.EdgesHelper(lineObject, 0x000000, 30)
      lines.material = this.coloring.objectLineMat
      wireframe.add(lines)

      parent.add(wireframe)
      return parent.wireframe = wireframe
    }

    const _addModel = model => {
      return model
        .getObject()
        .then(modelObject => {
          const geometry = threeConverter.toStandardGeometry(modelObject)

          if (this.globalConfig.rendering.showModel) {
            _addSolid(geometry, this.threeNode)
          }
          if (this.globalConfig.rendering.showShadowAndWireframe) {
            _addWireframe(geometry, this.threeNode)
          }

          return threeHelper.applyNodeTransforms(node, this.threeNode)
        })
    }

    this.afterCreationPromise = node.getModel()
      .then(_addModel)
    return this.afterCreationPromise
  }
}
