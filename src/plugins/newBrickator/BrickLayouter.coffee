Brick = require './Brick'

module.exports = class BrickLayouter
  constructor: () ->
    @nextBrickIndex = 0
    return

  nextBrickIdx: () =>
    temp = @nextBrickIndex
    @nextBrickIndex++
    return temp

  # main method called from outside the module
  layoutForGrid: (grid, profiling = false) =>
    if profiling
      console.log 'Step Layouting'
      start = new Date()

    bricks = @initializeBrickGraph grid

    if profiling
      initTime = new Date() - start
      console.log "Graph initialized in #{initTime}ms"

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

    # create all bricks
    for z in [0..grid.numVoxelsZ - 1] by 1
      for x in [0..grid.numVoxelsX - 1] by 1
        for y in [0..grid.numVoxelsY - 1] by 1

          if grid.zLayers[z]?[x]?[y]?
            if grid.zLayers[z][x][y] != false

              # create brick
              position = {x:x, y:y, z:z}
              size = {x: 1,y: 1,z: 1}
              brick = new Brick position, size
              grid.zLayers[z][x][y].brick = brick

              # create connection to and from the brick
              # below the current brick (if one exists)
              if z > 0 and grid.zLayers[z-1]?[x]?[y]? and
                           grid.zLayers[z-1][x][y] != false
                brickBelow = grid.zLayers[z-1][x][y].brick
                if brickBelow != false
                  brick.lowerSlots[0][0] = brickBelow
                  brickBelow.upperSlots[0][0] = brick

              bricks[z].push brick

    console.log bricks
    return bricks


  # main while loop condition:
  # any brick can still merge --> use heuristic:
  # keep a counter, break if last number of unsuccessful tries > (some number
  # or some % of total bricks in object)
  layoutByGreedyMerge: (bricks) =>
    console.log 'merging'

    numberOfRandomChoices = 0
    numberOfRandomChoicesWithoutMerge = 0
    while(true)
      brick = @chooseRandomBrick bricks
      numberOfRandomChoices++
      mergeableNeighbours = @findMergeableNeighbours brick, bricks
      if mergeableNeighbours.length == 0
        numberOfRandomChoicesWithoutMerge++
        if numberOfRandomChoicesWithoutMerge > 20
          console.log "randomChoices #{numberOfRandomChoices}
                      withoutMerge #{numberOfRandomChoicesWithoutMerge}"
          break # done with initial layout
        else
          continue # randomly choose a new brick

      while(mergeableNeighbours.length > 0)
        mergeNeighbours = @chooseNeighboursToMergeWith brick mergeableNeighbours
        @mergeBricksAndUpdateGraphConnections brick, mergeNeighbours
        mergeableNeighbours = @findMergeableNeighbours brick, bricks

    return bricks

  chooseRandomBrick: (bricks) =>
    brickLayer = bricks[Math.floor(Math.random() * bricks.length)]
    brick = brickLayer[Math.floor(Math.random() * bricks.length)]
    return brick

  findMergeableNeighbours: (brick, bricks) =>
    mergeableNeighbours = []
    return mergeableNeighbours

  chooseNeighboursToMergeWith: (brick, mergeableNeighbours) =>
    mergeNeighbours = []
    return mergeNeighbours


  mergeBricksAndUpdateGraphConnections: (brick, mergeNeighbours) =>
    return