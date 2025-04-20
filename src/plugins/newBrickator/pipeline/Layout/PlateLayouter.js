import log from "loglevel"

import Brick from "../Brick.js"
import * as Random from "../Random.js"
import Layouter from "./Layouter.js"


/*
 * @class PlateLayouter
 */
export default class PlateLayouter extends Layouter {
  constructor (pseudoRandom) {
    super()
    this._findMergeableNeighbors = this._findMergeableNeighbors.bind(this)
    this.finalLayoutPass = this.finalLayoutPass.bind(this)
    if (pseudoRandom == null) {
      pseudoRandom = false
    }
    Random.usePseudoRandom(pseudoRandom)
  }

  _isBrickLayouter () {
    return false
  }

  _isPlateLayouter () {
    return true
  }

  // Searches for mergeable neighbors in [x-, x+, y-, y+] direction
  // and returns an array out of arrays of IDs for each direction
  _findMergeableNeighbors (brick) {
    if (brick.getSize().z === 3) {
      return [null, null, null, null]
    }

    const mergeableNeighbors = []

    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Yp,
      obj => obj.x,
      obj => obj.y),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Ym,
      obj => obj.x,
      obj => obj.y),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Xm,
      obj => obj.y,
      obj => obj.x),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Xp,
      obj => obj.y,
      obj => obj.x),
    )

    return mergeableNeighbors
  }

  /*
   * Checks if brick can merge in the direction specified.
   *
   * @param {Brick} brick the brick whose neighbors to check
   * @param {Number} dir the merge direction as specified in Brick.direction
   * @param {Function} widthFn the function to determine the brick's width
   * @param {Function} lengthFn the function to determine the brick's length
   * @return {Array<Brick>} Bricks in the merge direction if this brick can merge
   * in this dir undefined otherwise.
   * @see Brick
   */
  _findMergeableNeighborsInDirection (brick, dir, widthFn, lengthFn) {
    const neighborsInDirection = brick.getNeighbors(dir)
    if (neighborsInDirection.size === 0) {
      return null
    }

    // Check that the neighbors together don't exceed this brick's width
    let width = 0
    let noMerge = false

    neighborsInDirection.forEach((neighbor) => {
      const neighborSize = neighbor.getSize()
      if (neighborSize.z !== brick.getSize().z) {
        noMerge = true
      }
      if (neighbor.getPosition().z !== brick.getPosition().z) {
        noMerge = true
      }
      return width += widthFn(neighborSize)
    })
    if (noMerge) {
      return null
    }

    // If they have the same accumulative width
    // check if they are in the correct positions,
    // i.e. no spacing between neighbors
    if (width !== widthFn(brick.getSize())) {
      return null
    }

    const minWidth = widthFn(brick.getPosition())

    const maxWidth = (minWidth + widthFn(brick.getSize())) - 1

    let length = null

    let invalidSize = false
    neighborsInDirection.forEach((neighbor) => {
      if (length == null) {
        length = lengthFn(neighbor.getSize())
      }
      if (widthFn(neighbor.getPosition()) < minWidth) {
        invalidSize = true
      }
      const neighborWidth = (widthFn(neighbor.getPosition()) +
        widthFn(neighbor.getSize())) - 1
      if (neighborWidth > maxWidth) {
        invalidSize = true
      }
      if (lengthFn(neighbor.getSize()) !== length) {
        return invalidSize = true
      }
    })
    if (invalidSize) {
      return null
    }

    if (Brick.isValidSize(widthFn(brick.getSize()), lengthFn(brick.getSize()) +
        length, brick.getSize().z)) {
      return neighborsInDirection
    }
    else {
      return null
    }
  }



  // Returns the index of the mergeableNeighbors sub-set-in-this-array,
  // where the bricks have the most connected neighbors.
  // If multiple sub-sets have the same number of connected neighbors,
  // one is randomly chosen
  _chooseNeighborsToMergeWith (mergeableNeighbors) {
    const numConnections = []
    let maxConnections = 0

    for (let i = 0; i < mergeableNeighbors.length; i++) {
      const neighborSet = mergeableNeighbors[i]
      if (neighborSet == null) {
        continue
      }

      var connectedBricks = new Set()

      neighborSet.forEach((neighbor) => {
        const neighborConnections = neighbor.connectedBricks()
        return neighborConnections.forEach(brick => connectedBricks.add(brick))
      })

      numConnections.push({
        num: connectedBricks.size,
        index: i,
      })

      maxConnections = Math.max(maxConnections, connectedBricks.size)
    }

    const largestConnections = numConnections.filter(element => element.num === maxConnections)

    const randomOfLargest = largestConnections[Random.next(largestConnections.length)]
    return randomOfLargest.index
  }

  finalLayoutPass (grid) {
    const bricksToLayout = grid.getAllBricks()
    let finalPassMerges = 0
    bricksToLayout.forEach(brick => {
      if (brick == null) {
        return
      }
      const merged = this._mergeLoop(brick, bricksToLayout)
      if (merged) {
        return finalPassMerges++
      }
    })

    log.debug("\tFinal pass merged ", finalPassMerges, " times.")
    return Promise.resolve({grid})
  }
}
