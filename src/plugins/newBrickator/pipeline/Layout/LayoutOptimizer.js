import log from "loglevel"

import * as DataHelper from "../DataHelper.js"
import * as Random from "../Random.js"


export default class LayoutOptimizer {
  constructor (brickLayouter, plateLayouter,
    pseudoRandom) {
    this.optimizeLayoutStability = this.optimizeLayoutStability.bind(this)
    this._findConnectedComponents = this._findConnectedComponents.bind(this)
    this._bricksOnComponentInterfaces = this._bricksOnComponentInterfaces.bind(this)
    this.splitBricksAndRelayoutLocally = this.splitBricksAndRelayoutLocally.bind(this)
    this.brickLayouter = brickLayouter
    this.plateLayouter = plateLayouter
    if (pseudoRandom == null) {
      pseudoRandom = false
    }
    Random.usePseudoRandom(pseudoRandom)
  }

  optimizeLayoutStability (grid) {
    let pass
    let asc; let end
    const maxNumPasses = 15

    for (pass = 0, end = maxNumPasses, asc = end >= 0; asc ? pass < end : pass > end; asc ? pass++ : pass--) {
      const bricks = grid.getAllBricks()
      log.debug("\t# of bricks: ", bricks.size)

      bricks.forEach(brick => brick.label = null)

      const numberOfComponents = this._findConnectedComponents(bricks)
      log.debug("\t# of components: ", numberOfComponents)

      const bricksToSplit = this._bricksOnComponentInterfaces(bricks)
      log.debug("\t# of bricks to split: ", bricksToSplit.size)

      if (bricksToSplit.size === 0) {
        break
      }
      else {
        this.splitBricksAndRelayoutLocally(bricksToSplit, grid, false, false)
      }
    }

    log.debug("\tfinished optimization after ", pass, "passes")
    return Promise.resolve(grid)
  }

  // Connected components using the connected component labelling algo
  _findConnectedComponents (bricks) {
    const labels = []
    let id = 0

    // First pass
    bricks.forEach((brick) => {
      const conBricks = brick.connectedBricks()
      const conLabels = new Set()

      conBricks.forEach((conBrick) => {
        if (conBrick.label != null) {
          return conLabels.add(conBrick.label)
        }
      })

      if (conLabels.size > 0) {
        const smallestLabel = DataHelper.smallestElement(conLabels)
        // Assign label to this brick
        brick.label = labels[smallestLabel]
        return (() => {
          const result = []
          for (let i = 0, end = labels.length, asc = end >= 0; asc ? i <= end : i >= end; asc ? i++ : i--) {
            if (conLabels.has(labels[i])) {
              result.push(labels[i] = labels[smallestLabel])
            }
            else {
              result.push(undefined)
            }
          }
          return result
        })()

      }
      else { // No neighbor has a label
        brick.label = id
        labels[id] = id

        return id++
      }
    })

    // Second pass - applying labels
    bricks.forEach(brick => brick.label = labels[brick.label])

    // Count number of components
    const finalLabels = new Set()
    for (const label of Array.from(labels)) {
      finalLabels.add(label)
    }
    const numberOfComponents = finalLabels.size

    return numberOfComponents
  }

  _bricksOnComponentInterfaces (bricks) {
    const bricksOnInterfaces = new Set()

    bricks.forEach((brick) => {
      const neighborsXY = brick.getNeighborsXY()
      return neighborsXY.forEach((neighbor) => {
        if (neighbor.label !== brick.label) {
          bricksOnInterfaces.add(neighbor)
          return bricksOnInterfaces.add(brick)
        }
      })
    })

    return bricksOnInterfaces
  }


  /*
   * Split up all supplied bricks into single bricks and relayout locally. This
   * means that all supplied bricks and (optionally) their neighbors
   * will be relayouted.
   *
   * @param {Set<Brick>} bricks bricks that should be split
   * @param {Grid} grid the grid the bricks belong to
   * @param {Boolean} [splitNeighbors=true ] whether or not neighbors will be
   * split up and relayouted
   * @param {Boolean} [useThreeLayers=true] whether BrickLayouter should be used
   * first before PlateLayouter
   */
  splitBricksAndRelayoutLocally (bricks, grid,
    splitNeighbors, useThreeLayers) {
    if (splitNeighbors == null) {
      splitNeighbors = true
    }
    if (useThreeLayers == null) {
      useThreeLayers = true
    }
    const bricksToSplit = new Set()

    bricks.forEach((brick) => {
      // add this brick to be split
      bricksToSplit.add(brick)


      if (splitNeighbors) {
        // Get neighbors in same z layer
        const neighbors = brick.getNeighborsXY()
        // Add them all to be split as well
        return neighbors.forEach(nBrick => bricksToSplit.add(nBrick))
      }
    })

    const newBricks = this._splitBricks(bricksToSplit)

    const bricksToBeDeleted = new Set()

    newBricks.forEach(brick => brick.forEachVoxel((voxel) => {
      // Delete bricks where voxels are disabled (3d printed)
      if (!voxel.enabled) {
        // Remove from relayout list
        bricksToBeDeleted.add(brick)
        // Delete brick from structure
        return brick.clear()
      }
    }))

    bricksToBeDeleted.forEach(brick => newBricks.delete(brick))

    if (useThreeLayers) {
      this.brickLayouter.layout(grid, newBricks)
    }
    return this.plateLayouter.layout(grid, newBricks)
      .then(() => ({
        removedBricks: bricksToSplit,
        newBricks,
      }))
  }

  // Splits each brick in bricks to split, returns all newly generated
  // bricks as a set
  _splitBricks (bricksToSplit) {
    const newBricks = new Set()

    bricksToSplit.forEach((brick) => {
      const splitGenerated = brick.splitUp()
      return splitGenerated.forEach(brick => newBricks.add(brick))
    })

    return newBricks
  }
}
