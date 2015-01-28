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
      brick.neighbours[0] = [grid.zLayers[z][x - 1][y].brick]
      grid.zLayers[z][x - 1][y].brick.neighbours[1] = [brick]
    return

  connectToBrickYm: (brick, x, y, z, grid) =>
    if y > 0 and grid.zLayers[z]?[x]?[y - 1]? and
        grid.zLayers[z][x][y - 1] != false
      brick.neighbours[2] = [grid.zLayers[z][x][y - 1].brick]
      grid.zLayers[z][x][y - 1].brick.neighbours[3] = [brick]
    return

  # main while loop condition:
  # any brick can still merge --> use heuristic:
  # keep a counter, break if last number of unsuccessful tries > (some number
  # or some % of total bricks in object)
  layoutByGreedyMerge: (bricks) =>
    console.log 'merging'

    numRandomChoices = 0
    numRandomChoicesWithoutMerge = 0
    maxNumRandomChoicesWithoutMerge = 1000

    while(numRandomChoices < 100) #only for debugging, should be while true
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
        mergeIndex = @chooseNeighboursToMergeWith brick,
          mergeableNeighbours
        brick = @mergeBricksAndUpdateGraphConnections brick,
          mergeableNeighbours, mergeIndex, bricks
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

    mergeableNeighbours.push @findMergeableNeighboursInDirection(
      brick
      0
      (obj) -> return obj.y
      (obj) -> return obj.x
    )
    mergeableNeighbours.push @findMergeableNeighboursInDirection(
      brick
      1
      (obj) -> return obj.y
      (obj) -> return obj.x
    )
    mergeableNeighbours.push @findMergeableNeighboursInDirection(
      brick
      2
      (obj) -> return obj.x
      (obj) -> return obj.y
    )
    mergeableNeighbours.push @findMergeableNeighboursInDirection(
      brick
      3
      (obj) -> return obj.x
      (obj) -> return obj.y
    )

    return mergeableNeighbours

  findMergeableNeighboursInDirection: (brick, dir, widthFn, lengthFn) =>
    if brick.neighbours[dir].length > 0
      width = 0
      for neighbour in brick.neighbours[dir]
        width += widthFn neighbour.size
      if width == widthFn(brick.size)
        minWidth = widthFn brick.position
        maxWidth = widthFn(brick.position) + widthFn(brick.size) - 1
        length = lengthFn(brick.neighbours[dir][0].size)
        for neighbour in brick.neighbours[dir]
          if widthFn(neighbour.position) < minWidth
            return
          else if widthFn(neighbour.position) +
          widthFn(neighbour.size) - 1 > maxWidth
            return
          if lengthFn(neighbour.size) != length
            return
        if Brick.isValidSize(widthFn(brick.size), lengthFn(brick.size) +
        length, brick.size.z)
          return brick.neighbours[dir]


  chooseNeighboursToMergeWith: (brick, mergeableNeighbours) =>
    connections = []
    numConnections = []

    # find unique connections of the theoretical future new brick
    for neighbours, i in mergeableNeighbours
      connections[i] = []
      if neighbours
        for neighbour in neighbours
          connections[i].push neighbour.uniqueConnectedBricks()
        connections[i] = removeDuplicates connections[i]
      numConnections[i] = connections[i].length

    # find the choice with the largest number of connections
    largestNumConnections = 0
    largestIndices = []
    for num, i in numConnections
      if num > largestNumConnections
        largestNumConnections = num
        largestIndices = [i]
        continue
      if num == largestNumConnections
        largestIndices.push i

    #console.log mergeableNeighbours
    #console.log numConnections
    #console.log largestIndices

    randomOfLargestIndices = largestIndices[Math.floor(Math.random() *
      largestIndices.length)]
    return randomOfLargestIndices

  mergeBricksAndUpdateGraphConnections: (
  brick, mergeableNeighbours, mergeIndex, bricks ) =>
    mergeNeighbours = mergeableNeighbours[mergeIndex]
    if mergeIndex == 1
      position = brick.position
      size = {
        x: brick.size.x + mergeNeighbours[0].size.x
        y: brick.size.y
        z: brick.size.z
      }

    else if mergeIndex == 0
      position = {
        x: mergeNeighbours[0].position.x
        y: brick.position.y
        z: brick.position.z
      }
      size = {
        x: brick.size.x + mergeNeighbours[0].size.x
        y: brick.size.y
        z: brick.size.z
      }

    else if mergeIndex == 3
      position = brick.position
      size = {
        x: brick.size.x
        y: brick.size.y + mergeNeighbours[0].size.y
        z: brick.size.z
      }

    else if mergeIndex == 2
      position = {
        x: brick.position.x
        y: mergeNeighbours[0].position.y
        z: brick.position.z
      }
      size = {
        x: brick.size.x
        y: brick.size.y + mergeNeighbours[0].size.y
        z: brick.size.z
      }

    newBrick = new Brick(position, size)

    for i in [0..4 - 1]
      newBrick.neighbours



    console.log 'MERGE'
    console.log mergeIndex
    console.log brick
    console.log mergeNeighbours
    console.log newBrick

    # set new brick connections & neighbours
    # delete outdated bricks from bricks array
    # add newBrick to bricks array

    return newBrick

  findWeakArticulationPointsInGraph: (bricks) =>
    return

  # helper method, to be moved somewhere more appropriate
  removeDuplicates = (array) ->
    a = array.concat()
    i = 0

    while i < a.length
      j = i + 1
      while j < a.length
        a.splice j--, 1  if a[i] is a[j]
        ++j
      ++i
    return a
