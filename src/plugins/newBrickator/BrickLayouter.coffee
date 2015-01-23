Brick = require './Brick'

module.exports = class BrickLayouter
  constructor: () ->
    @nextBrickIndex = 0
    return

  nextBrickIdx: () =>
    temp = @nextBrickIndex
    @nextBrickIndex++
    return temp

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
      if weakPoints.size > weakPointThreshold
        break

    if profiling
      elapsed = new Date() - start
      console.log "Step Layouting finished in #{elapsed}ms"

    return bricks

  initializeBrickGraph: (grid) =>
    bricks = []
    for z in [0..grid.numVoxelsZ - 1] by 1
      bricks[z] = []

    # first create all bricks
    for z in [0..grid.numVoxelsZ - 1] by 1
      for x in [0..grid.numVoxelsX - 1] by 1
        for y in [0..grid.numVoxelsY - 1] by 1
          if grid.zLayers[z]?[x]?[y]?
            if grid.zLayers[z][x][y] != false
              position = {x:x, y:y, z:z}
              size = {x: 1,y: 1,z: 1}
              brick = new Brick position, size
              bricks[z].push brick

    # then create all connections

    console.log bricks
    return bricks

  layoutByGreedyMerge: (bricks) =>
    while(anyBrickCanMerge)
      random = true
      brick = chooseBrick bricks, random
      mergeableNeighbours = []
      while(currentBrickHasMergeableNeighbours)
        mergeableNeighbours = findMergeableNeighbours brick, bricks
        mergeNeighbours = chooseNeighboursToMergeWith brick mergeableNeighbours bricks
        mergeBricksAndUpdateGraphConnections brick, mergeNeighbours, bricks
        mergeableNeighbours = findLegalNeighbours brick, bricks
    return bricks

  chooseBrick: () =>
    return