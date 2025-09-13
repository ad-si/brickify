import CsgExtractor from "./CsgExtractor.js"
import * as threeHelper from "../../client/threeHelper.js"
import clean from "./csgCleaner.js"
import * as threeConverter from "../../client/threeConverter.js"

export default class CSG {
  constructor () {
    this.init = this.init.bind(this)
    this.getCSG = this.getCSG.bind(this)
    this._createCSG = this._createCSG.bind(this)
  }

  init (bundle) {
    const {
      globalConfig,
    } = bundle
    return this.defaults = {
      minimalPrintVolume: globalConfig.minimalPrintVolume,
      holeSize: globalConfig.holeSize,
      studSize: globalConfig.studSize,
      addStuds: globalConfig.addStuds,
    }
  }

  /*
   * Returns a promise which will, when resolved, provide
   * the volumetric subtraction of ModelGeometry - LegoBricks
   * as a THREE.Mesh
   *
   * @return {THREE.Mesh} the volumetric subtraction
   * @param {Object} options the options which may consist out of:
   * @param {Object} options.studSize radius and height of LEGO studs
   * @param {Object} options.holeSize radius and height of holes for
   * LEGO studs
   * @param {Boolean} options.addStuds whether studs are added at all
   */
  getCSG (selectedNode, options) {
    if (options == null) {
      options = {}
    }
    this._applyDefaultValues(options)
    return this._getCachedData(selectedNode)
      .then(cachedData => {
        return this._createCSG(cachedData, selectedNode, options)
      })
  }

  // applies default values if they don't exist yet
  _applyDefaultValues (options) {
    return (() => {
      const result = []
      for (const key in this.defaults) {
        const value = this.defaults[key]
        if (options[key] == null) {
          result.push(options[key] = value)
        }
        else {
          result.push(undefined)
        }
      }
      return result
    })()
  }

  // returns own cached data and links grid from newBrickator data
  // resets newBrickator's csgNeedsRecalculation flag
  _getCachedData (selectedNode) {
    return selectedNode.getPluginData("csg")
      .then((data) => {
        if (data == null) {
          // create empty data set for own data
          data = {}
          selectedNode.storePluginData("csg", data, true)
        }

        // link grid and dirty flag from newBrickator
        return selectedNode.getPluginData("newBrickator")
          .then((newBrickatorData) => {
            data.grid = newBrickatorData.grid
            if (newBrickatorData.csgNeedsRecalculation) {
              data.csgNeedsRecalculation = true
            }
            newBrickatorData.csgNeedsRecalculation = false
            // finally return own data + newBrickator grid
            return data
          })
      })
  }

  // Creates a CSG subtraction between the node - lego voxels from grid
  _createCSG (cachedData, selectedNode, options) {
    if (!this._csgNeedsRecalculation(cachedData, options)) {
      return Promise.resolve(cachedData.csg)
    }

    return this._prepareModel(cachedData, selectedNode)
      .then(threeGeometry => {
        cachedData.transformedThreeGeometry = threeGeometry
        if (this.csgExtractor == null) {
          this.csgExtractor = new CsgExtractor()
        }

        options.transformedModel = cachedData.transformedThreeGeometry
        options.modelBsp = cachedData.modelBsp

        const result = this.csgExtractor.extractGeometry(cachedData.grid, options)
        cachedData.modelBsp = result.modelBsp

        options.split = true
        options.filterSmallGeometries = !result.isOriginalModel
        cachedData.csg = clean(result.csg, options)

        cachedData.csgNeedsRecalculation = false
        return cachedData.csg
      })
  }

  // Converts the optimized model from the selected node to a three model
  // that is transformed to match the grid
  _prepareModel (cachedData, selectedNode) {
    return new Promise((resolve, reject) => {
      if (cachedData.transformedThreeGeometry != null) {
        resolve(cachedData.transformedThreeGeometry)
        return
      }

      return selectedNode.getModel()
        .then((model) => {
          const threeGeometry = threeConverter.toStandardGeometry(model.model)
          threeGeometry.applyMatrix(threeHelper.getTransformMatrix(selectedNode))
          return resolve(threeGeometry)
        })
        .catch(error => reject(error))
    })
  }

  // determines whether the CSG operation needs recalculation
  _csgNeedsRecalculation (cachedData, options) {
    const newOptions = JSON.stringify(options)

    // check if options changed
    if (cachedData.oldOptions == null) {
      cachedData.oldOptions = newOptions
      return true
    }

    if (cachedData.oldOptions !== newOptions) {
      cachedData.oldOptions = newOptions
      return true
    }

    cachedData.oldOptions = newOptions

    // check if there was a brush action that forces us
    // to recreate CSG
    if (cachedData.csgNeedsRecalculation) {
      return true
    }
    return false
  }
}
