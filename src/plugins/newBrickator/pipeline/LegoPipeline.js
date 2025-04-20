import log from "loglevel"

import HullVoxelizer from "./voxelization/HullVoxelizer.js"
import VolumeFiller from "./voxelization/VolumeFiller.js"
import BrickLayouter from "./Layout/BrickLayouter.js"
import PlateLayouter from "./Layout/PlateLayouter.js"
import LayoutOptimizer from "./Layout/LayoutOptimizer.js"
import Random from "./Random.js"

export default class LegoPipeline {
  constructor () {
    this.run = this.run.bind(this)
    this.runPromise = this.runPromise.bind(this)
    this.terminate = this.terminate.bind(this)
    this.voxelizer = new HullVoxelizer()
    this.volumeFiller = new VolumeFiller()
    this.brickLayouter = new BrickLayouter()
    this.plateLayouter = new PlateLayouter()
    this.layoutOptimizer = new LayoutOptimizer(this.brickLayouter, this.plateLayouter)

    this.pipelineSteps = []
    this.pipelineSteps.push({
      name: "Hull voxelizing",
      decision (options) {
        return options.voxelizing
      },
      worker: (lastResult, options, progressCallback) => {
        return this.voxelizer.voxelize(
          lastResult.optimizedModel,
          options,
          progressCallback,
        )
      },
    })

    this.pipelineSteps.push({
      name: "Volume filling",
      decision (options) {
        return options.voxelizing
      },
      worker: (lastResult, options, progressCallback) => {
        return this.volumeFiller.fillGrid(
          lastResult.grid,
          lastResult.gridPOJO,
          options,
          progressCallback,
        )
      },
    })

    this.pipelineSteps.push({
      name: "Layout graph initialization",
      decision (options) {
        return options.initLayout
      },
      worker: (lastResult, options, progressCallback) => {
        return lastResult.grid.initializeBricks()
      },
    })

    this.pipelineSteps.push({
      name: "Layout Bricks",
      decision (options) {
        return options.layouting
      },
      worker: (lastResult, options) => {
        return this.brickLayouter.layout(lastResult.grid)
      },
    })

    this.pipelineSteps.push({
      name: "Layout Plates",
      decision (options) {
        return options.layouting
      },
      worker: (lastResult, options, progressCallback) => {
        return this.plateLayouter.layout(lastResult.grid)
      },
    })

    this.pipelineSteps.push({
      name: "Final merge pass",
      decision (options) {
        return options.layouting
      },
      worker: (lastResult, options) => {
        return this.plateLayouter.finalLayoutPass(lastResult.grid)
      },
    })

    this.pipelineSteps.push({
      name: "Local reLayout",
      decision (options) {
        return options.reLayout
      },
      worker: (lastResult, options, progressCallback) => {
        return this.layoutOptimizer.splitBricksAndRelayoutLocally(
          lastResult.modifiedBricks,
          lastResult.grid,
        )
      },
    })

    this.pipelineSteps.push({
      name: "Stability optimization",
      decision (options) {
        return options.layouting || options.reLayout
      },
      worker: (lastResult, options) => {
        return this.layoutOptimizer.optimizeLayoutStability(lastResult.grid)
      },
    })
  }

  run (data, options = null) {
    this.terminated = false
    log.debug(`Starting Lego Pipeline \
(voxelizing: ${options.voxelizing}, layouting: ${options.layouting}, \
onlyReLayout: ${options.reLayout})`,
    )

    const randomSeed = Math.floor(Math.random() * 1000000)
    Random.setSeed(randomSeed)
    log.debug("Using random seed", randomSeed)

    const start = new Date()

    const runPromise = this.runPromise(0, data, options)
      .then((result) => {
        log.debug(`Finished Lego Pipeline in ${new Date() - start}ms`)
        return result
      })

    const cancelPromise = new Promise((resolve, reject) => {
      this.reject = reject
    })

    return Promise.race([runPromise, cancelPromise])
  }

  runPromise (i, data, options) {
    const progressCallback = progress => {
      let overallProgress
      return overallProgress =
        ((100 * i) / this.pipelineSteps.length) + (progress / this.pipelineSteps.length)
    }
    const finished = (i >= this.pipelineSteps.length) || this.terminated
    if (finished) {
      this.currentStep = null
      this.terminated = true
      return data
    }
    else {
      return this.runStep(i, data, options, progressCallback)
        .then(result => {
          for (const key of Object.keys(result || {})) {
            data[key] = result[key]
          }
          return this.runPromise(++i, data, options, progressCallback)
        })
    }
  }

  runStep (i, lastResult, options, progressCallback) {
    const step = this.pipelineSteps[i]
    this.currentStep = step

    if (step.decision(options)) {
      log.debug(`Running step ${step.name}`)
      const start = new Date()
      return step.worker(lastResult, options, progressCallback)
        .then((result) => {
          const stop = new Date() - start
          log.debug(`Step ${step.name} finished in ${stop}ms`)
          return result
        })
    }
    else {
      log.debug(`(Skipping step ${step.name})`)
      return Promise.resolve(lastResult)
    }
  }

  terminate () {
    if (this.terminated) {
      return
    }
    this.terminated = true
    __guardMethod__(this.currentStep, "terminate", o => o.terminate())
    if (typeof this.reject === "function") {
      this.reject(`LegoPipeline was terminated at step ${this.currentStep.name}`)
    }
    this.currentStep = null
    return this.reject = null
  }
}

function __guardMethod__ (obj, methodName, transform) {
  if (typeof obj !== "undefined" && obj !== null && typeof obj[methodName] === "function") {
    return transform(obj, methodName)
  }
  else {
    return undefined
  }
}
