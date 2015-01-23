Brick = require './Brick'

module.exports = class BrickLayouter
  constructor: () ->
    @nextBrickIndex = 0
    @bricks = null
    return

  nextBrickIdx: () =>
    temp = @nextBrickIndex
    @nextBrickIndex++
    return temp

  countBricks: (grid) =>
    for z in [0..grid.numVoxelsZ - 1] by 1
      for x in [0..grid.numVoxelsX - 1] by 1
        for y in [0..grid.numVoxelsY - 1] by 1
          if @bricks.data[z]?[x]?[y]?
            if @bricks.data[z][x][y] != false
              @bricks.data[z][x][y].id = @nextBrickIdx()
    console.log @bricks.data
    return

  layoutForGrid: (grid, profiling = false) =>
    if profiling
      console.log 'Step Layouting'
      start = new Date()

    bricks = @initializeBrickGraph grid
    @layoutByGreedyMerge bricks

    if profiling
      initialTime = new Date() - start
      console.log "InitialLayout finished in #{initialTime}ms"

    # optimize for stability
    maxIterations = 50
    weakPointThreshold = 2
    weakPoints = findWeakArticulationPointsInGraph bricks
    for i in [0..maxIterations-1] by 1
      for wp in weakPoints
        neighbours = findAllNeighbours wp
        splitIntoSmallestBrick wp, neighbours
        layoutByGreedyMerge bricks
      weakPoints = findWeakArticulationPointsInGraph bricks
      if weakPoints.size > threshold
        break

    if profiling
      elapsed = new Date() - start
      console.log "Step Layouting finished in #{elapsed}ms"

    return bricks

  initializeBrickGraph: () =>
    bricks = []
    return bricks

  layoutByGreedyMerge: (bricks) =>
    while(anyBrickCanMerge)
      brick = chooseRandomBrick bricks
      mergeableNeighbours = []
      while(currentBrickHasMergeableNeighbours)
        mergeableNeighbours = findMergeableNeighbours brick, bricks
        mergeNeighbour = chooseNeighbourToMergeWith brick mergeableNeighbours bricks
        mergeBricksAndUpdateGraphConnections brick, mergeNeighbour, bricks
        mergeableNeighbours = findLegalNeighbours brick, bricks
    return bricks