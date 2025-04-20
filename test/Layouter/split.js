import chai from "chai"

import PlateLayouter from "../../src/plugins/newBrickator/pipeline/Layout/PlateLayouter.js"
import LayoutOptimizer from "../../src/plugins/newBrickator/pipeline/Layout/LayoutOptimizer.js"
import Grid from "../../src/plugins/newBrickator/pipeline/Grid.js"

const { expect } = chai

describe("brickLayouter split", () => it("should split one brick and relayout locally", () => {
  const plateLayouter = new PlateLayouter(true)
  const layoutOptimizer = new LayoutOptimizer(null, plateLayouter)
  const grid = new Grid()

  const v0 = grid.setVoxel({ x: 0, y: 0, z: 0 })
  const v1 = grid.setVoxel({ x: 1, y: 0, z: 0 })
  const v2 = grid.setVoxel({ x: 0, y: 1, z: 0 })
  const v3 = grid.setVoxel({ x: 1, y: 1, z: 0 })
  const v4 = grid.setVoxel({ x: 1, y: 2, z: 0 })

  grid.initializeBricks()

  // merge bricks to one single (invalid) brick
  v0.brick.mergeWith(v1.brick)
  v0.brick.mergeWith(v2.brick)
  v0.brick.mergeWith(v3.brick)
  v0.brick.mergeWith(v4.brick)

  // split it up and relayout
  layoutOptimizer.splitBricksAndRelayoutLocally([v0.brick], grid, true, false)

  // expect to be more than 1 brick
  const bricks = grid.getAllBricks()
  return expect(bricks.size > 1).to.equal(true)
}))
