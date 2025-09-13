import Brick from "../Brick.js"
import Voxel from "../Voxel.js"
import * as DataHelper from "../DataHelper.js"
import * as Random from "../Random.js"
import Layouter from "./Layouter.js"

/*
 * @class BrickLayouter
 */
export default class BrickLayouter extends Layouter {
  constructor (pseudoRandom) {
    super()
    this._findMergeableNeighbors = this._findMergeableNeighbors.bind(this)
    this._findMergeableNeighborsInDirection = this._findMergeableNeighborsInDirection.bind(this)
    this._minFractionOfConnectionsPresent = this._minFractionOfConnectionsPresent.bind(this)
    this._chooseNeighborsToMergeWith = this._chooseNeighborsToMergeWith.bind(this)
    this._findMergeableNeighborsUpOrDownwards = this._findMergeableNeighborsUpOrDownwards.bind(this)
    if (pseudoRandom == null) {
      pseudoRandom = false
    }
    Random.usePseudoRandom(pseudoRandom)
  }

  _isBrickLayouter () {
    return true
  }

  _isPlateLayouter () {
    return false
  }

  _findMergeableNeighbors (brick) {
    const mergeableNeighbors = []

    if (brick.getSize().z === 1) {
      mergeableNeighbors.push(this._findMergeableNeighborsUpOrDownwards(
        brick,
        Brick.direction.Zp,
      ),
      )
      mergeableNeighbors.push(this._findMergeableNeighborsUpOrDownwards(
        brick,
        Brick.direction.Zm,
      ),
      )
      return mergeableNeighbors
    }

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

  _findMergeableNeighborsInDirection (brick, dir, widthFn, lengthFn) {
    let voxel
    let mVoxel; let mVoxel2
    const {
      voxels,
    } = brick
    const mergeVoxels = new Set()
    const mergeBricks = new Set()

    if ((widthFn(brick.getSize()) > 2) && (lengthFn(brick.getSize()) >= 2)) {
      return null
    }

    // Find neighbor voxels, noMerge if any is empty
    const voxelIter = voxels.values()
    while (voxel = voxelIter.next().value) {
      mVoxel = voxel.neighbors[dir]
      if (mVoxel == null) {
        return null
      }
      if (mVoxel.brick !== brick) {
        mergeVoxels.add(mVoxel)
      }
    }

    // Find neighbor bricks,
    // noMerge if any not present
    // noMerge if any brick not 1x1x1
    let mergeVoxelIter = mergeVoxels.values()
    while (mVoxel = mergeVoxelIter.next().value) {
      const mBrick = mVoxel.brick
      if (!mBrick || !mBrick.isSize(1, 1, 1)) {
        return null
      }
      mergeBricks.add(mBrick)
    }

    const allVoxels = DataHelper.union([voxels, mergeVoxels])

    let size = Voxel.sizeFromVoxels(allVoxels)
    if (Brick.isValidSize(size.x, size.y, size.z)) {
      if (this._minFractionOfConnectionsPresent(allVoxels)) {
        return mergeBricks
      }
    }

    // Check another set of voxels in merge direction, starting from mergeVoxels
    // This is necessary for the 2 brick steps of larger bricks
    const mergeVoxels2 = new Set()
    mergeVoxelIter = mergeVoxels.values()
    while (mVoxel = mergeVoxelIter.next().value) {
      mVoxel2 = mVoxel.neighbors[dir]
      if (mVoxel2 == null) {
        return null
      }
      mergeVoxels2.add(mVoxel2)
    }

    const mergeVoxel2Iter = mergeVoxels2.values()
    while (mVoxel2 = mergeVoxel2Iter.next().value) {
      const mBrick2 = mVoxel2.brick
      if (!mBrick2 || !mBrick2.isSize(1, 1, 1)) {
        return null
      }
      mergeBricks.add(mBrick2)
    }

    mergeVoxels2.forEach(mVoxel2 => allVoxels.add(mVoxel2))

    size = Voxel.sizeFromVoxels(allVoxels)
    if (Brick.isValidSize(size.x, size.y, size.z)) {
      if (this._minFractionOfConnectionsPresent(allVoxels)) {
        return mergeBricks
      }
    }

    return null
  }

  /*
    Check if at least half of the top and half of the bottom voxels
    offer connection possibilities
    This is used as a heuristic to determine whether or not to merge bricks:
    if a brick has less than minFraction connection
    it may lead to a more unstable layout
  */
  _minFractionOfConnectionsPresent (voxels) {
    const minFraction = .51
    const fraction = Voxel.fractionOfConnections(voxels)
    return fraction >= minFraction
  }

  _chooseNeighborsToMergeWith (mergeableNeighbors) {
    const numBricks = []
    let maxBricks = 0

    for (let i = 0; i < mergeableNeighbors.length; i++) {
      const neighborSet = mergeableNeighbors[i]
      if (neighborSet == null) {
        continue
      }
      numBricks.push({
        num: neighborSet.size,
        index: i,
      })
      maxBricks = Math.max(maxBricks, neighborSet.size)
    }

    const largestConnections = numBricks.filter(element => element.num === maxBricks)

    const randomOfLargest = largestConnections[Random.next(largestConnections.length)]
    return randomOfLargest.index
  }

  // Assumes brick is 1x1x1
  _findMergeableNeighborsUpOrDownwards (brick, _direction) {
    if (brick.getSize().z !== 1) {
      return null
    }

    const secondLayerBricks = brick.getNeighbors(Brick.direction.Zp)
    if (secondLayerBricks.size !== 1) {
      return null
    }

    const slBrick = secondLayerBricks.values()
      .next().value
    if (!slBrick.isSize(1, 1, 1)) {
      return null
    }

    const thirdLayerBricks = slBrick.getNeighbors(Brick.direction.Zp)
    if (thirdLayerBricks.size !== 1) {
      return null
    }

    const tlBrick = thirdLayerBricks.values()
      .next().value
    if (!tlBrick.isSize(1, 1, 1)) {
      return null
    }

    const neighbors = new Set()
    neighbors.add(slBrick)
    neighbors.add(tlBrick)
    return neighbors
  }
}
