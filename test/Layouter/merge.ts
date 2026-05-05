import { expect } from "chai"

import PlateLayouter from "../../src/plugins/newBrickator/pipeline/Layout/PlateLayouter.js"
import Grid from "../../src/plugins/newBrickator/pipeline/Grid.js"
import Brick from "../../src/plugins/newBrickator/pipeline/Brick.js"

type PlateLayouterWithPrivate = PlateLayouter & {
  _findMergeableNeighbors: (brick: Brick) => (Set<Brick> | null)[]
  _chooseNeighborsToMergeWith: (neighbors: (Set<Brick> | null)[]) => number
}

describe("brickLayouter merge", () => {
  it("should find mergeable neighbor brick xp and xm", () => {
    const grid = new Grid()
    const v0 = grid.setVoxel({x: 0, y: 0, z: 0})
    const v1 = grid.setVoxel({x: 1, y: 0, z: 0})

    const plateLayouter = new PlateLayouter()
    void grid.initializeBricks()

    let mergeableNeighbors = (plateLayouter as PlateLayouterWithPrivate)._findMergeableNeighbors(v0.brick as Brick)
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const mergeableNeighborsXp = mergeableNeighbors[3]!
    expect(mergeableNeighborsXp.has(v1.brick as Brick)).to.equal(true)

    mergeableNeighbors = (plateLayouter as PlateLayouterWithPrivate)._findMergeableNeighbors(v1.brick as Brick)
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const mergeableNeighborsXm = mergeableNeighbors[2]!
    return expect(mergeableNeighborsXm.has(v0.brick as Brick)).to.equal(true)
  })

  it("should find mergeable neighbor brick yp and ym", () => {
    const grid = new Grid()
    const v0 = grid.setVoxel({x: 0, y: 0, z: 0})
    const v1 = grid.setVoxel({x: 0, y: 1, z: 0})

    const plateLayouter = new PlateLayouter()
    void grid.initializeBricks()

    let mergeableNeighbors = (plateLayouter as PlateLayouterWithPrivate)._findMergeableNeighbors(v0.brick as Brick)
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const mergeableNeighborsYp = mergeableNeighbors[0]!
    expect(mergeableNeighborsYp.has(v1.brick as Brick)).to.equal(true)

    mergeableNeighbors = (plateLayouter as PlateLayouterWithPrivate)._findMergeableNeighbors(v1.brick as Brick)
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const mergeableNeighborsYm = mergeableNeighbors[1]!
    return expect(mergeableNeighborsYm.has(v0.brick as Brick)).to.equal(true)
  })

  it("should choose the better brick 10 out of 10 times", () => {
    const grid = new Grid()
    grid.setVoxel({x: 0, y: 0, z: 0})
    const v0 = grid.setVoxel({x: 1, y: 0, z: 0})
    const v1 = grid.setVoxel({x: 2, y: 0, z: 0})
    grid.setVoxel({x: 2, y: 0, z: 1})

    const plateLayouter = new PlateLayouter()
    void grid.initializeBricks()
    const brick = v0.brick as Brick

    return (() => {
      const result: Chai.Assertion[] = []
      for (let num = 1; num <= 10; num++) {
        const mergeableNeighbors = (plateLayouter as PlateLayouterWithPrivate)._findMergeableNeighbors(brick)
        const mergeDirection =
          (plateLayouter as PlateLayouterWithPrivate)._chooseNeighborsToMergeWith(mergeableNeighbors)

        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        result.push(expect(mergeableNeighbors[mergeDirection]!.has(v1.brick as Brick)).to.equal(true))
      }
      return result
    })()
  })

  it("should not merge a single voxel", () => {
    const grid = new Grid()
    const v0 = grid.setVoxel({x: 5, y: 5, z: 0})
    const plateLayouter = new PlateLayouter()

    void grid.initializeBricks()
    void plateLayouter.layout(grid)

    expect((v0.brick as Brick).getPosition()).to.eql({x: 5, y: 5, z: 0})
    return expect((v0.brick as Brick).getSize()).to.eql({x: 1, y: 1, z: 1})
  })

  it("should merge two bricks 2x1", () => {
    const grid = new Grid()
    const v0 = grid.setVoxel({x: 5, y: 5, z: 0})
    const v1 = grid.setVoxel({x: 5, y: 6, z: 0})
    const plateLayouter = new PlateLayouter()

    void grid.initializeBricks()
    void plateLayouter.layout(grid)

    expect(grid.getAllBricks().size).to.equal(1)
    expect(v0.brick).to.equal(v1.brick)
    expect((v0.brick as Brick).getPosition()).to.eql({x: 5, y: 5, z: 0})
    return expect((v0.brick as Brick).getSize()).to.eql({x: 1, y: 2, z: 1})
  })

  it("should merge four bricks", () => {
    const grid = new Grid()
    const v0 = grid.setVoxel({x: 5, y: 5, z: 0})
    grid.setVoxel({x: 5, y: 6, z: 0})
    grid.setVoxel({x: 6, y: 5, z: 0})
    grid.setVoxel({x: 6, y: 6, z: 0})

    const plateLayouter = new PlateLayouter()
    void grid.initializeBricks()
    void plateLayouter.layout(grid)

    expect(grid.getAllBricks().size).to.equals(1)
    expect((v0.brick as Brick).getPosition()).to.eql({x: 5, y: 5, z: 0})
    return expect((v0.brick as Brick).getSize()).to.eql({x: 2, y: 2, z: 1})
  })

  // Verifies the two-step neighbor lookup for plates: a 1x4 plate next to two
  // consecutive 1x1 plates can merge directly into a 1x6 plate, even though
  // the intermediate 1x5 size is invalid.
  it("should merge a 1x4 plate with two 1x1 neighbors into a 1x6", () => {
    const grid = new Grid()
    const voxels = [
      grid.setVoxel({x: 0, y: 0, z: 0}),
      grid.setVoxel({x: 0, y: 1, z: 0}),
      grid.setVoxel({x: 0, y: 2, z: 0}),
      grid.setVoxel({x: 0, y: 3, z: 0}),
      grid.setVoxel({x: 0, y: 4, z: 0}),
      grid.setVoxel({x: 0, y: 5, z: 0}),
    ]

    void grid.initializeBricks()

    // Replace the four 1x1 bricks at y=0..3 with a single 1x4 brick. The
    // remaining two voxels at y=4 and y=5 stay as 1x1 bricks.
    const longBrick = new Brick(voxels.slice(0, 4).map(v => v))

    const plateLayouter = new PlateLayouter()
    const mergeable = (plateLayouter as PlateLayouterWithPrivate)
      ._findMergeableNeighbors(longBrick)
    const yp = mergeable[0]

    expect(yp).to.not.equal(null)
    /* eslint-disable @typescript-eslint/no-non-null-assertion */
    expect(yp!.size).to.equal(2)
    expect(yp!.has(voxels[4].brick as Brick)).to.equal(true)
    expect(yp!.has(voxels[5].brick as Brick)).to.equal(true)
    /* eslint-enable @typescript-eslint/no-non-null-assertion */
  })

  // Negative case: a 1x4 plate next to a single 1x1 plate would yield an
  // invalid 1x5. Ensure the layouter does not propose that merge.
  it("should not merge a 1x4 with a single 1x1 (would be invalid 1x5)", () => {
    const grid = new Grid()
    const voxels = [
      grid.setVoxel({x: 0, y: 0, z: 0}),
      grid.setVoxel({x: 0, y: 1, z: 0}),
      grid.setVoxel({x: 0, y: 2, z: 0}),
      grid.setVoxel({x: 0, y: 3, z: 0}),
      grid.setVoxel({x: 0, y: 4, z: 0}),
    ]

    void grid.initializeBricks()
    const longBrick = new Brick(voxels.slice(0, 4).map(v => v))

    const plateLayouter = new PlateLayouter()
    const mergeable = (plateLayouter as PlateLayouterWithPrivate)
      ._findMergeableNeighbors(longBrick)

    expect(mergeable[0]).to.equal(null)
  })
})
