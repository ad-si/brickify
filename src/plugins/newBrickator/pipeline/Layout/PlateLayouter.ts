import log from "loglevel"

import Brick from "../Brick.js"
import * as DataHelper from "../DataHelper.js"
import * as Random from "../Random.js"
import Layouter from "./Layouter.js"
import type Grid from "../Grid.js"

interface Size3D {
  x: number
  y: number
  z: number
}

interface Position3D {
  x: number
  y: number
  z: number
}

/*
 * @class PlateLayouter
 */
export default class PlateLayouter extends Layouter {
  constructor (pseudoRandom?: boolean) {
    super()
    this._findMergeableNeighbors = this._findMergeableNeighbors.bind(this)
    this.finalLayoutPass = this.finalLayoutPass.bind(this)
    if (pseudoRandom == null) {
      pseudoRandom = false
    }
    Random.usePseudoRandom(pseudoRandom)
  }

  protected _isBrickLayouter (): boolean {
    return false
  }

  protected _isPlateLayouter (): boolean {
    return true
  }

  // Searches for mergeable neighbors in [x-, x+, y-, y+] direction
  // and returns an array out of arrays of IDs for each direction
  protected _findMergeableNeighbors (brick: Brick): (Set<Brick> | null)[] {
    if (brick.getSize().z === 3) {
      return [null, null, null, null]
    }

    const mergeableNeighbors: (Set<Brick> | null)[] = []

    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Yp,
      (obj: Size3D) => obj.x,
      (obj: Size3D) => obj.y),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Ym,
      (obj: Size3D) => obj.x,
      (obj: Size3D) => obj.y),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Xm,
      (obj: Size3D) => obj.y,
      (obj: Size3D) => obj.x),
    )
    mergeableNeighbors.push(this._findMergeableNeighborsInDirection(
      brick,
      Brick.direction.Xp,
      (obj: Size3D) => obj.y,
      (obj: Size3D) => obj.x),
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
  _findMergeableNeighborsInDirection (
    brick: Brick,
    dir: string,
    widthFn: (obj: Size3D | Position3D) => number,
    lengthFn: (obj: Size3D | Position3D) => number
  ): Set<Brick> | null {
    if (widthFn(brick.getSize()) > 2 && lengthFn(brick.getSize()) >= 2) {
      return null
    }

    const neighbors = brick.getNeighbors(dir)
    if (neighbors.size === 0) {
      return null
    }

    const firstLength = this._checkNeighbors(brick, neighbors, widthFn, lengthFn)
    if (firstLength === null) {
      return null
    }

    if (Brick.isValidSize(
      widthFn(brick.getSize()),
      lengthFn(brick.getSize()) + firstLength,
      brick.getSize().z,
    )) {
      return neighbors
    }

    // The neighbors line up with the brick but the combined size is invalid
    // (e.g. 1x4 + 1x1 = 1x5). Try one more row out — combining with the
    // neighbors-of-neighbors might land on a valid size (e.g. 1x4 + 1x1 + 1x1
    // = 1x6).
    const neighborsOfNeighbors = new Set<Brick>()
    neighbors.forEach((neighbor) => {
      neighbor.getNeighbors(dir).forEach(nn => neighborsOfNeighbors.add(nn))
    })

    const secondLength = this._checkNeighbors(
      brick, neighborsOfNeighbors, widthFn, lengthFn,
    )
    if (secondLength === null) {
      return null
    }

    if (Brick.isValidSize(
      widthFn(brick.getSize()),
      lengthFn(brick.getSize()) + firstLength + secondLength,
      brick.getSize().z,
    )) {
      return DataHelper.union([neighbors, neighborsOfNeighbors])
    }

    return null
  }

  // Validates that the given neighbors line up with brick along its width,
  // share the same z-layer, and all have equal length. Returns the per-row
  // length the neighbors would add to the brick, or null if not mergeable.
  _checkNeighbors (
    brick: Brick,
    neighbors: Set<Brick>,
    widthFn: (obj: Size3D | Position3D) => number,
    lengthFn: (obj: Size3D | Position3D) => number,
  ): number | null {
    if (neighbors.size === 0) {
      return null
    }

    const minWPos = widthFn(brick.getPosition())
    const maxWPos = minWPos + widthFn(brick.getSize()) - 1

    let totalNeighborWidth = 0
    let neighborLength: number | null = null

    const iter = neighbors.values()
    let next = iter.next()
    while (!next.done) {
      const neighbor = next.value
      const nSize = neighbor.getSize()
      const nPos = neighbor.getPosition()

      if (nSize.z !== brick.getSize().z) return null
      if (nPos.z !== brick.getPosition().z) return null

      if (widthFn(nPos) < minWPos) return null
      if (widthFn(nPos) + widthFn(nSize) - 1 > maxWPos) return null

      if (neighborLength === null) {
        neighborLength = lengthFn(nSize)
      }
      else if (lengthFn(nSize) !== neighborLength) {
        return null
      }

      totalNeighborWidth += widthFn(nSize)
      next = iter.next()
    }

    if (totalNeighborWidth !== widthFn(brick.getSize())) {
      return null
    }

    return neighborLength
  }



  // Returns the index of the mergeableNeighbors sub-set-in-this-array,
  // where the bricks have the most connected neighbors.
  // If multiple sub-sets have the same number of connected neighbors,
  // one is randomly chosen
  protected _chooseNeighborsToMergeWith (mergeableNeighbors: (Set<Brick> | null)[]): number {
    const numConnections: { num: number; index: number }[] = []
    let maxConnections = 0

    for (let i = 0; i < mergeableNeighbors.length; i++) {
      const neighborSet = mergeableNeighbors[i]
      if (neighborSet == null) {
        continue
      }

      const connectedBricks = new Set<Brick>()

      neighborSet.forEach((neighbor: Brick) => {
        const neighborConnections = neighbor.connectedBricks()
        neighborConnections.forEach(brick => connectedBricks.add(brick))
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

  finalLayoutPass (grid: Grid | undefined): Promise<{ grid: Grid | undefined }> {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const bricksToLayout = grid!.getAllBricks()
    let finalPassMerges = 0
    bricksToLayout.forEach((brick): void => {
      const merged = this._mergeLoop(brick, bricksToLayout)
      if (merged) {
        finalPassMerges++
      }
    })

    log.debug("\tFinal pass merged ", finalPassMerges, " times.")
    return Promise.resolve({grid})
  }
}
