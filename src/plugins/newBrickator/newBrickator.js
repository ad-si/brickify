import stlExporter from "stl-exporter"
import log from "loglevel"

import LegoPipeline from "./pipeline/LegoPipeline.js"
import PipelineSettings from "./pipeline/PipelineSettings.js"
import Brick from "./pipeline/Brick.js"
import * as threeHelper from "../../client/threeHelper.js"
import * as threeConverter from "../../client/threeConverter.js"
// Spinner is only available in the browser; load lazily when needed

/*
 * @class NewBrickator
 */
export default class NewBrickator {
  constructor () {
    this.init = this.init.bind(this)
    this.onNodeAdd = this.onNodeAdd.bind(this)
    this.onNodeRemove = this.onNodeRemove.bind(this)
    this.runLegoPipeline = this.runLegoPipeline.bind(this)
    this.relayoutModifiedParts = this.relayoutModifiedParts.bind(this)
    this._createDataStructure = this._createDataStructure.bind(this)
    this.getNodeData = this.getNodeData.bind(this)
    this.getDownload = this.getDownload.bind(this)
    this._prepareCSGOptions = this._prepareCSGOptions.bind(this)
    this.getHotkeys = this.getHotkeys.bind(this)
    this.pipeline = new LegoPipeline()
    this.Spinner = null
    this._runWithSpinner = this._runWithSpinner.bind(this)
  }

  init (bundle) {
    this.bundle = bundle
  }

  onNodeAdd (node) {
    this.nodeVisualizer = this.bundle.getPlugin("nodeVisualizer")
    return this._runWithSpinner(() =>
      this.getNodeData(node)
        .then(cachedData => {
          if (this.nodeVisualizer != null) {
            this.nodeVisualizer.objectModified(node, cachedData)
          }
        })
    ).catch(error => {
      const msg = (error && (error.stack || error.message)) ? (error.stack || error.message) : String(error)
      log.error("newBrickator.onNodeAdd failed:", msg)
    })
  }

  onNodeRemove (node) {
    return this.pipeline.terminate()
  }

  runLegoPipeline (selectedNode) {
    return this._runWithSpinner(() =>
      this.getNodeData(selectedNode)
        .then(cachedData => {
          // since cached data already contains voxel grid, only run lego
          const settings = new PipelineSettings(this.bundle.globalConfig)
          settings.deactivateVoxelizing()

          settings.setModelTransform(threeHelper.getTransformMatrix(selectedNode))

          const data = {
            optimizedModel: cachedData.optimizedModel,
            grid: cachedData.grid,
          }

          return this.pipeline.run(data, settings, true)
            .then(() => {
              cachedData.csgNeedsRecalculation = true

              if (this.nodeVisualizer != null) {
                this.nodeVisualizer.objectModified(selectedNode, cachedData)
              }
            })
        })
    ).catch(error => {
      const msg = (error && (error.stack || error.message)) ? (error.stack || error.message) : String(error)
      log.error("newBrickator.runLegoPipeline failed:", msg)
    })
  }

  /*
   * If voxels have been selected as lego / as 3d print, the brick layout
   * needs to be locally regenerated
   * @param {Object} cachedData reference to cachedData
   * @param {Array<BrickObject>} modifiedVoxels list of voxels that have
   * been modified
   * @param {Boolean} createBricks creates Bricks if a voxel has no associated
   * brick. this happens when using the lego brush to create new bricks
   */
  relayoutModifiedParts (selectedNode, modifiedVoxels, createBricks) {
    if (createBricks == null) {
      createBricks = false
    }
    log.debug("relayouting modified parts, creating bricks:", createBricks)
    return this.getNodeData(selectedNode)
      .then(cachedData => {
        const modifiedBricks = new Set()
        for (const v of Array.from(modifiedVoxels)) {
          if (v.brick) {
            modifiedBricks.add(v.brick)
          }
          else if (createBricks) {
            modifiedBricks.add(new Brick([v]))
          }
        }

        const settings = new PipelineSettings(this.bundle.globalConfig)
        settings.onlyRelayout()

        const data = {
          optimizedModel: cachedData.optimizedModel,
          grid: cachedData.grid,
          modifiedBricks,
        }

        return this.pipeline.run(data, settings, true)
          .then(() => {
            cachedData.csgNeedsRecalculation = true

            return this.nodeVisualizer != null ? this.nodeVisualizer.objectModified(selectedNode, cachedData) : undefined
          })
      })
      .catch(error => {
        const msg = (error && (error.stack || error.message)) ? (error.stack || error.message) : String(error)
        log.error("newBrickator.relayoutModifiedParts failed:", msg)
      })
  }

  _createDataStructure (selectedNode) {
    return selectedNode.getModel()
      .then(model => {
      // Create grid
        const settings = new PipelineSettings(this.bundle.globalConfig)
        settings.setModelTransform(threeHelper.getTransformMatrix(selectedNode))

        return this.pipeline.run(
          {optimizedModel: model},
          settings,
          true,
        )
          .then((results) => {
          // Create data structure
            const data = {
              node: selectedNode,
              grid: results.grid,
              optimizedModel: model,
              csgNeedsRecalculation: false,
            }
            selectedNode.storePluginData("newBrickator", data, true)
            return data
          })
      })
  }

  _checkDataStructure (selectedNode, data) {
    return true // Later: Check for node transforms
  }

  getNodeData (selectedNode) {
    return selectedNode.getPluginData("newBrickator")
      .then(data => {
        if ((data != null) && this._checkDataStructure(selectedNode, data)) {
          return data
        }
        else {
          return this._createDataStructure(selectedNode)
        }
      })
  }

  getDownload (selectedNode, downloadOptions) {
    if (downloadOptions.type !== "stl") {
      return null
    }

    const options = this._prepareCSGOptions(
      downloadOptions.studRadius, downloadOptions.holeRadius,
    )

    if (this.csg == null) {
      this.csg = this.bundle.getPlugin("csg")
    }
    if (this.csg == null) {
      log.warn("Unable to create download due to CSG Plugin missing")
      return Promise.resolve({ data: "", fileName: "" })
    }

    const downloadPromise = new Promise((resolve, reject) => {
      return this.csg
        .getCSG(selectedNode, options)
        .then((csgGeometries) => {

          if ((csgGeometries == null) || (csgGeometries.length === 0)) {
            resolve([{
              data: "",
              fileName: "",
            }])
            return
          }

          return selectedNode
            .getName()
            .then((name) => {

              const results = csgGeometries.map((threeGeometry, index) => {

                const fileName = "brickify-" +
              name.replace(/.stl$/, "" +
              `-${index}.stl`,
              )

                const faceVertexMesh = threeConverter
                  .threeGeometryToFaceVertexMesh(threeGeometry)

                faceVertexMesh.name = name

                return {
                  data: stlExporter.toBinaryStl(faceVertexMesh),
                  fileName,
                }
              })

              return resolve(results)
            })
        })
        .catch((error) => {
          log.error(error)
          return reject(error)
        })
    })

    return downloadPromise
  }

  _prepareCSGOptions (studRadius, holeRadius) {
    const options = {}

    // Set stud and hole size
    if (studRadius != null) {
      options.studSize = {
        radius: studRadius,
        height: this.bundle.globalConfig.studSize.height,
      }
    }

    if (holeRadius != null) {
      options.holeSize = {
        radius: holeRadius,
        height: this.bundle.globalConfig.holeSize.height,
      }
    }

    // Add studs
    options.addStuds = true

    return options
  }

  getHotkeys () {
    if (process.env.NODE_ENV !== "development") {
      return
    }
    return {
      title: "newBrickator",
      events: [
        {
          hotkey: "c",
          description: "cancel current pipeline operation",
          callback: () => this.pipeline.terminate(),
        },
      ],
    }
  }

  async _runWithSpinner (action) {
    // Ensure Spinner module is loaded first to avoid start/stop race
    if (typeof window === "undefined") {
      return action()
    }
    if (!this.Spinner) {
      try {
        this.Spinner = await import("../../client/Spinner.js")
      } catch (_e) {
        // If spinner cannot be loaded, run action without it
        return action()
      }
    }
    const target = this.bundle.renderer.getDomElement()
    this.Spinner.startOverlay(target)
    try {
      return await action()
    } finally {
      this.Spinner.stop(target)
    }
  }
}
