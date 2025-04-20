import log from "loglevel"

import * as Random from "../Random.js"
import * as DataHelper from "../DataHelper.js"

/*
 * @class PlateLayouter
 *
 * Abstract class containing most of the execution logic
 * for inheriting classes
 */

export default class Layouter {
  constructor () {
  }

  /*
   * Performs one layout pass.
   *
   * @param {Grid} grid the grid that contains the voxels/bricks to be layouted
   * @param {Set<Brick>} [bricksToLayout] if present, layouter only works on
   * the bricks in this set, not on the entire grid
   * @return {Grid} updated version of the original grid passed to the function
   */
  layout (grid, bricksToLayout) {
    let numRandomChoices = 0
    let numRandomChoicesWithoutMerge = 0
    let numTotalInitialBricks = 0

    if (bricksToLayout == null) {
      bricksToLayout = grid.getAllBricks()
      bricksToLayout.chooseRandomBrick = grid.chooseRandomBrick
    }

    numTotalInitialBricks += bricksToLayout.size
    const maxNumRandomChoicesWithoutMerge = numTotalInitialBricks
    if (!(numTotalInitialBricks > 0)) {
      return Promise.resolve({grid})
    }

    MAINLOOP: // ;
    while (true) {
      const brick = this._chooseRandomBrick(bricksToLayout)
      if (brick == null) {
        return Promise.resolve({grid})
      }
      numRandomChoices++

      if (this._isPlateLayouter() && (brick.getSize().z === 3)) {
        bricksToLayout.delete(brick)
        if (bricksToLayout.size === 0) {
          return Promise.resolve({grid})
        }
        continue
      }

      const merged = this._mergeLoop(brick, bricksToLayout)

      if (!merged) {
        numRandomChoicesWithoutMerge++
        if (numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge) {
          log.debug(`\trandomChoices ${numRandomChoices} \
withoutMerge ${numRandomChoicesWithoutMerge}`,
          )
          // Done with layout
          break
        }
        else {
          // Choose a new brick
          continue
        }
      }

      if (this._isBrickLayouter()) {
        // If brick is 1x1x3, 1x2x3 or instable after mergeLoop
        // break it into pieces ...
        if (brick.isSize(1, 1, 3) || (brick.getStability() === 0) ||
        brick.isSize(1, 2, 3)) {
          // .. unless it has no neighbors ..
          var neighbor
          const neighbors = brick.getNeighborsXY()
          if (neighbors.size === 0) {
            continue
          }
          const neighborIterator = neighbors.values()
          // .. unless all neighbors are already bricks
          while (neighbor = neighborIterator.next().value) {
            if (neighbor.getSize().z === 1) {
              const newBricks = brick.splitUp()
              bricksToLayout.delete(brick)
              newBricks.forEach(newBrick => bricksToLayout.add(newBrick))
              continue MAINLOOP// ;
            }
          }
        }
      }
    }

    return Promise.resolve({grid})
  }

  // Chooses a random brick out of the set
  _chooseRandomBrick (setOfBricks) {
    if (setOfBricks.size === 0) {
      return null
    }

    if (setOfBricks.chooseRandomBrick != null) {
      return setOfBricks.chooseRandomBrick()
    }

    let rnd = Random.next(setOfBricks.size)

    const iterator = setOfBricks.entries()
    let brick = iterator.next().value[0]
    while (rnd > 0) {
      brick = iterator.next().value[0]
      rnd--
    }

    return brick
  }

  _mergeBricksAndUpdateGraphConnections (brick,
    mergeNeighbors, bricksToLayout) {
    mergeNeighbors.forEach((neighborToMergeWith) => {
      bricksToLayout.delete(neighborToMergeWith)
      return brick.mergeWith(neighborToMergeWith)
    })
    return brick
  }


  _mergeLoop (brick, bricksToLayout) {
    let merged = false

    let mergeableNeighbors = this._findMergeableNeighbors(brick)

    while (DataHelper.anyDefinedInArray(mergeableNeighbors)) {
      merged = true
      const mergeIndex = this._chooseNeighborsToMergeWith(mergeableNeighbors)
      const neighborsToMergeWith = mergeableNeighbors[mergeIndex]

      this._mergeBricksAndUpdateGraphConnections(brick,
        neighborsToMergeWith, bricksToLayout)

      if (!brick.isValid()) {
        log.warn("Invalid brick: ", brick)
        log.warn("> current seed:", Random.getSeed())
      }

      mergeableNeighbors = this._findMergeableNeighbors(brick)
    }

    return merged
  }
}
