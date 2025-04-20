import Grid from "../Grid.js"

const floatDelta = 1e-10
const voxelRoundingThreshold = 1e-5

import HullVoxelWorker from "./HullVoxelWorker.js"

export default class Voxelizer {
  constructor () {
    this.voxelize = this.voxelize.bind(this)
    this.terminate = this.terminate.bind(this)
    this._getOptimizedVoxelSpaceModel = this._getOptimizedVoxelSpaceModel.bind(this)
    this.voxelGrid = null
  }

  _addDefaults (options) {
    if (options.accuracy == null) {
      options.accuracy = 16
    }
    return options.zTolerance != null ? options.zTolerance : options.zTolerance = 0.01
  }

  voxelize (model, options, progressCallback) {
    if (options == null) {
      options = {}
    }
    this._addDefaults(options)

    return new Promise((resolve, reject) => {
      return this.setupGrid(model, options)
        .then(voxelGrid => {

          const lineStepSize = voxelGrid.heightRatio / options.accuracy

          const progressAndFinishedCallback = message => {
            if (message.state === "progress") {
              return progressCallback(message.progress)
            }
            else { // if state is 'finished'
              return resolve({
                grid: voxelGrid,
                gridPOJO: message.data,
              })
            }
          }

          return this._getOptimizedVoxelSpaceModel(model, options)
            .then(voxelSpaceModel => {
              this.worker = this._getWorker()
              return this.worker.voxelize(
                voxelSpaceModel,
                lineStepSize,
                floatDelta,
                voxelRoundingThreshold,
                progressAndFinishedCallback,
              )
            })
        })
        .catch(error => reject(console.error))
    })
  }

  terminate () {
    if (this.worker != null) {
      this.worker.terminate()
    }
    return this.worker = null
  }

  _getOptimizedVoxelSpaceModel (model, options) {
    return model
      .getFaceVertexMesh()
      .then(faceVertexMesh => {
        let i
        let end
        let end1
        const coordinates = faceVertexMesh.vertexCoordinates
        const voxelSpaceCoordinates = new Array(coordinates.length)
        for (i = 0, end = coordinates.length; i < end; i += 3) {
          const position = {
            x: coordinates[i],
            y: coordinates[i + 1],
            z: coordinates[i + 2],
          }
          const coordinate = this.voxelGrid.mapModelToVoxelSpace(position)
          voxelSpaceCoordinates[i] = coordinate.x
          voxelSpaceCoordinates[i + 1] = coordinate.y
          voxelSpaceCoordinates[i + 2] = coordinate.z
        }

        const normals = faceVertexMesh.faceNormalCoordinates
        const directions = []
        for (i = 2, end1 = normals.length; i < end1; i += 3) {
          const z = normals[i]
          directions.push(this._getTolerantDirection(z, options.zTolerance))
        }

        return {
          coordinates: voxelSpaceCoordinates,
          faceVertexIndices: faceVertexMesh.faceVertexIndices,
          directions,
        }
      })
  }

  _getWorker () {
    if (this.worker != null) {
      return this.worker
    }
    return operative(HullVoxelWorker)
  }

  _getTolerantDirection (dZ, tolerance) {
    if (dZ > tolerance) {
      return 1
    }
    else if (dZ < -tolerance) {
      return -1
    }
    else {
      return 0
    }
  }

  setupGrid (model, options) {
    this.voxelGrid = new Grid(options.gridSpacing)

    return this.voxelGrid
      .setUpForModel(model, options)
      .then(() => {
        return this.voxelGrid
      })
  }
}
