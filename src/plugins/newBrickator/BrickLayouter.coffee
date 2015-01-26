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
    ###
    # optimize for stability
    maxIterations = 50
    weakPointThreshold = 2
    weakPoints = @findWeakArticulationPointsInGraph bricks
    for i in [0..maxIterations-1] by 1
      for wp in weakPoints
        neighbours = @findAllNeighbours wp
        @splitIntoSmallestBrick wp, neighbours
        @layoutByGreedyMerge bricks
      weakPoints = @findWeakArticulationPointsInGraph bricks
      if weakPoints.size > weakPointThreshold
        break
    ###
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
              position = {x: x, y: y, z: z}
              size = {x: 1,y: 1,z: 1}
              brick = new Brick position, size
              grid.zLayers[z][x][y].brick = brick

              @connectToBrickBelow brick, x,y,z, grid
              @connectToBrickXm brick, x,y,z, grid
              @connectToBrickYm brick, x,y,z, grid

              bricks[z].push brick

    # console.log bricks
    return bricks

  connectToBrickBelow: (brick, x, y, z, grid) =>
    if z > 0 and grid.zLayers[z - 1]?[x]?[y]? and
        grid.zLayers[z - 1][x][y] != false
      brickBelow = grid.zLayers[z - 1][x][y].brick
      brick.lowerSlots[0][0] = brickBelow
      brickBelow.upperSlots[0][0] = brick
    return

  connectToBrickXm: (brick, x, y, z, grid) =>
    if x > 0 and grid.zLayers[z]?[x - 1]?[y]? and
        grid.zLayers[z][x - 1][y] != false
      brick.neighbours.xm = [grid.zLayers[z][x - 1][y].brick]
      grid.zLayers[z][x - 1][y].brick.neighbours.xp = [brick]
    return

  connectToBrickYm: (brick, x, y, z, grid) =>
    if y > 0 and grid.zLayers[z]?[x]?[y - 1]? and
        grid.zLayers[z][x][y - 1] != false
      brick.neighbours.ym = [grid.zLayers[z][x][y - 1].brick]
      grid.zLayers[z][x][y - 1].brick.neighbours.yp = [brick]
    return

  # main while loop condition:
  # any brick can still merge --> use heuristic:
  # keep a counter, break if last number of unsuccessful tries > (some number
  # or some % of total bricks in object)
  layoutByGreedyMerge: (bricks) =>
    console.log 'merging'

    numRandomChoices = 0
    numRandomChoicesWithoutMerge = 0
    maxNumRandomChoicesWithoutMerge = 20
    while(numRandomChoices < 100)
      brick = @chooseRandomBrick bricks
      numRandomChoices++
      #console.log numRandomChoices
      mergeableNeighbours = @findMergeableNeighbours brick
      if mergeableNeighbours.length == 0
        numRandomChoicesWithoutMerge++
        if numRandomChoicesWithoutMerge > maxNumRandomChoicesWithoutMerge
          console.log "randomChoices #{numRandomChoices}
                      withoutMerge #{numRandomChoicesWithoutMerge}"
          break # done with initial layout
        else
          continue # randomly choose a new brick

      while(mergeableNeighbours.length > 0)
        #console.log mergeableNeighbours.length
        mergeNeighbours = @chooseNeighboursToMergeWith brick,
          mergeableNeighbours
        @mergeBricksAndUpdateGraphConnections brick, mergeNeighbours
        mergeableNeighbours = [] #@findMergeableNeighbours brick, bricks

    return bricks

  chooseRandomBrick: (bricks) =>
    brickLayer = bricks[Math.floor(Math.random() * bricks.length)]
    while brickLayer.length is 0 # if a layer has no bricks, retry
      brickLayer = bricks[Math.floor(Math.random() * bricks.length)]
    brick = brickLayer[Math.floor(Math.random() * brickLayer.length)]
    return brick

  findMergeableNeighbours: (brick) =>
    mergeableNeighbours = []
    # should probably be refactored at some point :)
    mergeableNeighbours.push @findMergeableNeighboursXm brick
    mergeableNeighbours.push @findMergeableNeighboursXp brick
    mergeableNeighbours.push @findMergeableNeighboursYm brick
    mergeableNeighbours.push @findMergeableNeighboursYp brick
    # console.log mergeableNeighbours
    return mergeableNeighbours

  findMergeableNeighboursXp: (brick) =>
    # console.log 'xp'
    xDim = 0
    for neighbour in brick.neighbours.xp
      xDim += neighbour.size.x
      if neighbour.size.y != 1
        return
    if xDim == brick.size.x
      return brick.neighbours.xp
    return

  findMergeableNeighboursXm: (brick) =>
    # console.log 'xm'
    xDim = 0
    for neighbour in brick.neighbours.xm
      xDim += neighbour.size.x
      if neighbour.size.y != 1
        return
    if xDim == brick.size.x
      return brick.neighbours.xm
    return

  findMergeableNeighboursYp: (brick) =>
    # console.log 'yp'
    yDim = 0
    for neighbour in brick.neighbours.yp
      yDim += neighbour.size.y
      if neighbour.size.x != 1
        return
    if yDim == brick.size.y
      return brick.neighbours.yp
    return

  findMergeableNeighboursYm: (brick) =>
    # console.log 'ym'
    yDim = 0
    for neighbour in brick.neighbours.ym
      yDim += neighbour.size.y
      if neighbour.size.x != 1
        return
    if yDim == brick.size.y
      return brick.neighbours.ym
    return

  chooseNeighboursToMergeWith: (brick, mergeableNeighbours) =>
    mergeNeighbours = []
    return mergeNeighbours


  mergeBricksAndUpdateGraphConnections: (brick, mergeNeighbours) =>
    return

  findWeakArticulationPointsInGraph: (bricks) =>
    return
