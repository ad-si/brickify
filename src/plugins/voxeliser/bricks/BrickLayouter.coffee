Vector3D = require '../geometry/Vector3D'

class BrickLayouter

  constructor: (@layout) ->
    # Saves possible brick heights (except for standard height 1)
    @heights = []
    # Determines if scene models will be rendered in layouting substeps
    @debugging = false

    @initHeights()

# ------------------------
# PUBLIC METHODS - CAN BE CALLED FROM OUTSIDE
# ------------------------

  getLayout: ->
    return @layout


  printLayoutStats: ->
    console.log ' -----------------'
    console.log ' STATISTICS'
    console.log ' -----------------'
    stats = @layout.get_Statistics()
    console.log ' LegoGraph:'
    for key, val of stats
      if val instanceof Object
        console.log key
        str = ''
        for k, v of val
          str += '  [' + k + ' : ' + v + ']'
        console.log str
      else
        console.log key + ' : ' + val


  # Main layouting method
  layoutAll: ->
    #return null if @layout.is_layouted

    oldBricks = @layout.all_bricks.clone()

    # Establish layout graph (upper and lower bricks)
    @buildGraph()
    console.log 'Built Lego Graph'

    console.log 'Start layouting with ' + @layout.get_BrickCount() + ' bricks'
    @layoutAllBricks()
    console.log 'Done layouting.'

    @printLayoutStats()

    @layout.is_layouted = yes

    if not @debugging
      # Update visible scene models
      for brick in oldBricks
        brick.remove_SceneModel()
      for brick in @layout.all_bricks
        brick.update_SceneModel()

      #@layout.update_SceneModel()


  splitBricks: (bricks, keepHeight) ->
    basicBricks = []
    for b in bricks
      basicBricks = basicBricks.concat(@resetToBasicBricks(b, keepHeight))

    basicBricks


  mergeBricks: (bricks, keepHeight) ->
    if not keepHeight
      bricks = @preprocessHeightsBlockwise(bricks)

    @growBricks(bricks)


  mergeBrickBlock: (bricks, keepHeight) ->
    if not keepHeight
      bricks = @preprocessHeightsBlockwise(bricks)

    @growBricks(bricks, yes)


# ------------------------
# PRIVATE METHODS - SHOULD NOT BE CALLED FROM OUTSIDE
# ------------------------

  layoutAllBricks: ->

    # CHOOSE ONE ALGORITHM
    @preprocessHeightsLayerwise(@layout.all_bricks)
    # @preprocessHeightsBlockwise(@layout.all_bricks)

    @layoutInitially()
    console.log 'Initial layout done. Remaining bricks: ' +
      @layout.get_BrickCount()

    if @layout.extent.z > 1
      @fixOverhangingBricks(200)
      @fixWeakBricks(10)
      @fixOverhangingBricks(200)

    console.log 'Finished layouting.'


  initHeights: ->
    if @heights.is_empty()
      # Find all unusual heights > 1
      @heights = []
      for type in @layout.bricksystem.brick_types
        if type.height > 1 and @heights.indexOf(type.height) == -1
          @heights.push type.height
      @heights.sort (a,b) -> b - a


  preprocessHeightsBlockwise: (processableBricks) ->
    # Imagine: We're searching bottom-up for same BLOCKS using
    #          a sliding window
    for slider in @heights
      layerBricks = @splitBrickArrayLayerwise processableBricks
      newBricks = []

      for bricks in layerBricks
        for brick in bricks
          if not brick.slots? # Can already be merged
            continue

          uppers = []
          mergeUp = yes

          for i in [1...slider]
            upperBrick = @layout.get_Brick(brick.position.x,
              brick.position.y, brick.position.z + i)

            if not upperBrick? or
            not layerBricks[brick.position.z + i].includes(upperBrick) or
            upperBrick.id == brick.id
              mergeUp = no
              break
            else
              uppers.push upperBrick

          if mergeUp
            newBrick = @merge brick, uppers
            newBricks.push newBrick

      processableBricks = newBricks

    processableBricks


  preprocessHeightsLayerwise: (processableBricks) ->
    # Imagine: We're searching bottom-up for same LAYERS using
    #          a sliding window
    for slider in @heights
      layerBricks = @splitBrickArrayLayerwise processableBricks
      newBricks = []

      z = 0
      while z + slider - 1 < layerBricks.length
        bricks = layerBricks[z]

        if bricks.length != 0 # Layer has bricks

          # Check if above layers have the same number of bricks
          sameBrickamount = yes
          for i in [1...slider]
            bricksAbove = layerBricks[z + i]
            if bricks.length != bricksAbove.length
              sameBrickamount = no
              break

          if not sameBrickamount
            z += 1
            continue

          # Check if they have in fact the same bricks
          mergeUp = yes
          for brick in bricks
            for i in [1...slider]
              upperBrick = @layout.get_Brick(brick.position.x, brick.position.y,
                brick.position.z + i)
              if not upperBrick? or
              not layerBricks[z + i].includes(upperBrick) or
              upperBrick.id == brick.id
                mergeUp = no
                break
            break if not mergeUp

          if mergeUp
            newBricks = newBricks.concat @mergeLayers(z, slider, layerBricks)
            z += (slider - 1)

        z += 1

      processableBricks = newBricks

    processableBricks


  mergeLayers: (layerIdx, height, layerBricks) ->
    bricks = layerBricks[layerIdx]
    newBricks = []

    for brick in bricks
      uppers = []
      for i in [1...height]
        br = @layout.get_Brick(brick.position.x, brick.position.y,
          brick.position.z + i)
        if br? and layerBricks[layerIdx + i].includes(br)
          uppers.push br

      if not uppers.length == height - 1
        console.log 'ERROR: Merging layers went wrong.'

      newBrick = @merge brick, uppers
      newBricks.push newBrick

    newBricks


  splitBrickArrayLayerwise: (bricks) ->
    layerBricks = []
    for i in [0...@layout.extent.z] by 1
      layerBricks.push([])

    for brick in bricks
      layerBricks[brick.position.z].push brick

    # Depending on input, this might look like
    #  layerbricks = [..., [], [b1, b2], [b3, b4, b5], [], ... ]
    layerBricks


  fixOverhangingBricks: (maxIterations) ->
    # Fix overhanging bricks
    # Recursive, to keep easy possibility of a timeout to see what's going on
    badBricks = @findOverhangingBricks()
    badBricks = @fixBricks(badBricks, 1, maxIterations)

    numOverhanging = badBricks['overhanging'].length
    if numOverhanging == 0
      console.log 'SUCCESS: Model buildable, no overhanging bricks'
    else
      console.log 'Stop fixing overhanging bricks. Still ' + numOverhanging +
        ' overhanging bricks after ' + maxIterations + ' iterations.'


  fixWeakBricks: (maxIterations) ->
    # Fix weak points
    badBricks = @findWeakArticulationBricks()
    badBricks = @fixBricks(badBricks, 1, maxIterations)
    numWeak = badBricks['weak'].length
    if numWeak == 0
      console.log 'SUCCESS: No weak bricks found in the model'
    else
      console.log 'Stop fixing weak bricks. Still ' + numWeak +
        ' weak bricks after ' + maxIterations + ' iterations.'



  fixBricks: (badBricks, iteration, maxIterations) ->
    if 'overhanging' of badBricks and
    badBricks['overhanging'].length > 0 and
    iteration <= maxIterations
      console.log 'Try fixing ' + badBricks['overhanging'].length +
        ' overhanging bricks: Iteration ' + iteration
      @tryFixOverlappers(badBricks)
      console.log 'Overhanging bricks fix iteration: ' + iteration +
        ' complete. Total bricks: ' + @layout.get_BrickCount() + ' bricks'

      badBricks = @findOverhangingBricks()
      iteration += 1

      # DEBUG
      # setTimeout(=>
      #   @fixBricks(badBricks, iteration, maxIterations)
      # , 1000)
      return @fixBricks(badBricks, iteration, maxIterations)

    else if 'weak' of badBricks and
    badBricks['weak'].length > 0 and
    iteration <= maxIterations
      console.log 'Try fixing ' + badBricks['weak'].length +
        ' weak bricks: Iteration ' + iteration
      console.log badBricks['weak']
      @tryFixWeakPoints(badBricks)
      console.log 'Weak bricks fix iteration: ' + iteration +
        ' complete. Remaining bricks: ' + @layout.get_BrickCount() + ' bricks'

      badBricks = @findWeakArticulationBricks()
      iteration += 1

      # DEBUG
      # setTimeout(=>
      #   @fixBricks(badBricks, iteration, maxIterations)
      # , 1000)
      return @fixBricks(badBricks, iteration, maxIterations)

    return badBricks


  findOverhangingBricks: ->
    # Bad = if brick is overhanging OR is direct
    # neighbor of an overhanging brick
    overhangingBricks = []
    badNeighborBricks = []

    graphs = @findSubgraphs()
    if graphs.length > 1
      # Sort graphs by brickcount descending
      graphs.sort((a,b) ->
        return (Object.keys(b).length - Object.keys(a).length))

      # DEBUG
      # console.log 'Found subgraphs:'
      # console.log graphs

      # Bricks not in graphs[0] (the biggest) can be declared 'overhanging'
      bricksToSplit = {}
      for i in [1..graphs.length - 1] # leave biggest graph out of splitting
        for id, brick of graphs[i]
          bricksToSplit[id] = brick
          for dir, bricks of @getLayerNeighbors(brick)
            if dir == 'left' or dir == 'right' or
            dir == 'top' or dir == 'bottom' or
            dir
              for b in bricks
                if b.id not of bricksToSplit
                  bricksToSplit[b.id] = b

      # Perform split and save returned 1x1 bricks
      for id, b of bricksToSplit
        if id of graphs[0]
          badNeighborBricks.push(b)
        else
          overhangingBricks.push(b)

    badBricks = {}
    badBricks['overhanging'] = overhangingBricks
    badBricks['neighbors'] = badNeighborBricks
    return badBricks


  layoutInitially: ->
    @growBricks(@layout.all_bricks)


  tryFixWeakPoints: (badBricks) ->
    # Reset bricks
    bad1x1Bricks = []
    for brick in badBricks['weak']
      bad1x1Bricks = bad1x1Bricks.concat(@resetToBasicBricks(brick, yes))

    @growBricks(bad1x1Bricks)

    @printLayoutStats()


  tryFixOverlappers: (badBricks) ->
    # Reset bricks
    bad1x1Bricks = {'overhanging': [], 'neighbors': []}
    for type, bricks of badBricks
      for brick in bricks
        bad1x1Bricks[type] = bad1x1Bricks[type].concat(
          @resetToBasicBricks(brick, yes))

    overhangingBricks = bad1x1Bricks['overhanging']
    badNeighborBricks = bad1x1Bricks['neighbors']

    # TODO: Start with overhanging bricks and try to grow to the good neighbors
    # direction
    # Neighbors are bricks connected to the rest of the model (not overhanging,
    # but neighbors overhanging bricks)
    growableBricks = overhangingBricks.concat(badNeighborBricks)

    @growBricks(growableBricks)


  growBricks: (bricks, useAsWhiteList = no) ->
    # Important not to touch bricks
    growableBricks = bricks.clone()
    grownBricks = []

    while growableBricks.length > 0
      # Choosing random 1x1-brick to fix by growing
      brickIndex = parseInt(Math.random() * growableBricks.length)
      brick = growableBricks[brickIndex]
      growableBricks.splice(brickIndex, 1)

      # brick might already be merged with by a previous growBrick
      if brick.slots != null

        if useAsWhiteList
          brick = @growBrick(brick, bricks)
        else
          brick = @growBrick(brick)

        grownBricks.push brick
        if @debugging
          brick.update_SceneModel()

    # Bricks might have grown into other grown bricks
    for b in grownBricks
      if b?.slots == null
        grownBricks.remove(b)

    grownBricks


  buildGraph: ->
    for brick in @layout.all_bricks
      @buildGraphConnections(brick)


  buildGraphConnections: (brick) ->
    brick.upperBricks = {}
    brick.lowerBricks = {}
    if brick.position.z + brick.extent.z < @layout.extent.z
      # Check upper layer
      brick.upperBricks = @buildLayerConnections(brick.position.z +
        brick.extent.z, brick)
    if brick.position.z > 0
      # Check lower layer
      brick.lowerBricks = @buildLayerConnections(brick.position.z - 1, brick)


  buildLayerConnections: (layerIdx, brick) ->
    connectedBricks = {}
    for [x,y] in brick.get_XY_Slots()
      br = @layout.get_Brick(x, y, layerIdx)
      if br?
        if br.id not in connectedBricks
          connectedBricks[br.id] = br
    return connectedBricks


  findSubgraphs: ->
    # Result will look like:
    #   graphs = [{1:brick1, 2:brick2, 3:brick3 }, {4:brick4, 5:brick5 } ]
    graphs = []

    numBricksFound = 0
    while numBricksFound != @layout.get_BrickCount()
      if numBricksFound > @layout.get_BrickCount()
        console.log 'Error: There\'s something wrong with the graph'

      startingBrick = @layout.all_bricks[0]
      startId = startingBrick.id

      # Find a starting brick that is not part of the graphs yet
      if graphs.length > 0
        for brick in @layout.all_bricks
          found = false
          for graph in graphs
            if brick.id of graph
              found = true
          if not found
            startingBrick = brick
            break
        if startingBrick.id == startId
          console.log 'Error: This should not happen, check your graph traversal
           algorithm, bro!'
          console.log graphs
          console.log numBricksFound
          remaining = @legoGrid.all_bricks.clone()
          zombie = []
          for graph in graphs
            for key,value of graph
              remaining.remove value
              if ! @legoGrid.all_bricks.includes value
                zombie.push value
          console.warn 'Error'
          console.log remaining
          console.log zombie
          return null

      # Use the starting brick to traverse all connected nodes
      graphs.push(@findGraph(startingBrick))

      numBricksFound = 0
      for obj in graphs
        numBricksFound += Object.keys(obj).length

    return graphs


  findWeakArticulationBricks: ->
    weakBricks = {}
    graphs = @findSubgraphs()

    for brick in @layout.all_bricks
      # Temporarily remove brick from graph
      lowers = brick.lowerBricks
      uppers = brick.upperBricks
      for id, l of lowers
        delete l.upperBricks[brick.id]
      for id, u of uppers
        delete u.lowerBricks[brick.id]
      brick.lowerBricks = {}
      brick.upperBricks = {}

      # Check for changed graph connectivity
      # Will contain the just removed brick in a separate graph
      newGraphs = @findSubgraphs()
      if newGraphs.length == graphs.length
        console.log 'ERROR: Weakbrick-Graphs have the same length!'
      if newGraphs.length - 1 != graphs.length
        subgraphsLongerThanOne = 0
        for graph in newGraphs
          if Object.keys(graph).length > 1
            subgraphsLongerThanOne += 1

        if subgraphsLongerThanOne > 1
          weakBricks[brick.id] = brick
          for dir, bricks of @getLayerNeighbors(brick)
            if dir == 'left' or
            dir == 'right' or
            dir == 'top' or
            dir == 'bottom' or
            dir
              for b in bricks
                if b.id not of weakBricks
                  weakBricks[b.id] = b

      # Add brick back to the graph
      brick.lowerBricks = lowers
      brick.upperBricks = uppers
      for id, l of lowers
        l.upperBricks[brick.id] = brick
      for id, u of uppers
        u.lowerBricks[brick.id] = brick

    # TODO: weird to make it a list and then an object again, just because
    # of the overhanging bricks structure, figure out something better here
    weak = []
    for id, b of weakBricks
      weak.push b

    badBricks = {}
    badBricks['weak'] = weak
    return badBricks


  findGraph: (startingBrick) ->
    # Breadth-first search algorithm
    num = 0
    graph = {} # used to mark
    graph[startingBrick.id] = startingBrick
    visitNeeded = [] # used as a queue for traversal
    visitNeeded.push(startingBrick)

    while visitNeeded.length > 0
      brick = visitNeeded.pop() # pop the traversal queue
      connections = @getGraphConnections(brick)
      for id, b of connections
        if id not of graph # if marked
          if id == undefined
            console.log 'whooot'
          graph[id] = b # mark
          visitNeeded.push(b) # enqueue

    return graph


  getGraphConnections: (brick) ->
    conn = {}
    for id, b of brick.upperBricks
      conn[id] = b
    for id, b of brick.lowerBricks
      conn[id] = b
    return conn


  calculateBestNeighbors: (brick, neighbors) ->
    # Idea: Best neighbors are those that create the most connections among the
    # Lego graph
    bestNeighbors = null
    maxCreatedConnections = -1

    for direction, neighborBricks of neighbors
      if @isLegalMerge(brick, neighborBricks)
        createdConnections = @caluculateCreatedConnections(brick,
          neighborBricks)

        # Find max
        if createdConnections > maxCreatedConnections
          maxCreatedConnections = createdConnections
          bestNeighbors = [[neighborBricks.slice(0), direction]]
        else if createdConnections == maxCreatedConnections
          bestNeighbors.push [neighborBricks.slice(0), direction]

    bestNeighbors


  getZigzagBricks: (brick, bestNeighbors) ->
    zigzags = null

    for [bricks, direction] in bestNeighbors
      if brick.position.z % 2 == 0 and
        (direction == 'top' or direction == 'bottom' or
        direction == 'topbottom' or direction == 'bottom2' or
        direction == 'top2')
          zigzags = bricks
          break
      else if brick.position.z % 2 != 0 and
        (direction == 'left' or direction == 'right' or
        direction == 'leftright' or direction == 'right2' or
        direction == 'left2')
          zigzags = bricks
          break

    zigzags


  filterNeighbors: (neighbors, brickWhiteList) ->
    filteredBricks = {}

    for direction, neighborBricks of neighbors
      bricksOk = yes
      for brick of neighborBricks
        if not brickWhiteList.includes brick
          bricksOk = no
          break

      if bricksOk
        filteredBricks[direction] = neighborBricks

    filteredBricks


  growBrick: (brick, brickWhiteList = null) ->
    while true
      neighbors = @getLayerNeighbors(brick)

      if brickWhiteList?
        neighbors = @filterNeighbors(neighbors, brickWhiteList)

        if Object.keys(neighbors).length == 0
          break

      bestNeighbors = @calculateBestNeighbors(brick, neighbors)

      if bestNeighbors == null
        break

      if bestNeighbors.length > 1
        # There are multiple possible directions
        # => choose a zig-zag pattern
        bricksToMerge = @getZigzagBricks(brick, bestNeighbors)

        if bricksToMerge != null
          # Merge according to zigzag pattern
          brick = @merge brick, bricksToMerge
          continue

      # No need or not possible to apply zigzag pattern
      brick = @merge brick, bestNeighbors[0][0]

    return brick


  caluculateCreatedConnections: (brick, bricks) ->
    curConn = @calculateConnections([brick])
    newConn = 0
    lower = {}
    upper = {}

    for id, br of brick.lowerBricks
      lower[id] = true
    for id, br of brick.upperBricks
      upper[id] = true

    for b in bricks
      for id, br of b.lowerBricks
        lower[id] = true
      for id, br of b.upperBricks
        upper[id] = true

    newConn += Object.keys(lower).length
    newConn += Object.keys(upper).length

    return newConn - curConn


  calculateConnections: (bricks) ->
    connections = 0

    for b in bricks
      connections += Object.keys(b.upperBricks).length
      connections += Object.keys(b.lowerBricks).length

    return connections


  getLayerNeighbors: (brick) ->
    # ----------------
    # FOR A 1x3x3 BRICK, NEIGHBORS COULD LOOK LIKE THIS:
    # NEIGHBORS = {
    #   left: [brick1, brick2, brick3]
    #   right: [brick4, brick5, brick6]
    #   top: [brick7]
    #   bottom: [brick7]
    #   ...
    # }
    # Merge is done with ALL of one neighbor-direction IF legal
    #
    # IMAGINE: A brick can be high, deep and wide, making neighbor search
    #  a search of all bricks next to a 'wall' of single 1x1 bricks
    # IMAGINE: For the directions you look on the model from the top (only X and
    # Y visible)
    # ----------------
    neighbors = {}
    directions = ['left', 'right', 'top', 'bottom', 'topbottom', 'leftright',
                  'top2', 'left2', 'right2', 'bottom2']

    pushNeighborBrick = (direction, neighbors, x, y, z) =>
      br = @layout.get_Brick(x, y, z)
      if br? and br not in neighbors[direction]
        neighbors[direction].push(br)

    while directions.length > 0
      # Draw a random direction
      index = parseInt(Math.random() * directions.length)
      direction = directions[index]
      directions.splice(index, 1)

      neighbors[direction] = []

    # Left
    if brick.position.x > 0
      for y in [0...brick.extent.y] by 1
        for z in [0...brick.extent.z] by 1
          pushNeighborBrick('left', neighbors, brick.position.x - 1,
            y + brick.position.y, z + brick.position.z)

    # Right
    if brick.position.x + brick.extent.x < @layout.extent.x
      for y in [0...brick.extent.y] by 1
        for z in [0...brick.extent.z] by 1
          pushNeighborBrick('right', neighbors,
            brick.position.x + brick.extent.x, y + brick.position.y,
            z + brick.position.z)

    # Top
    if brick.position.y > 0
      for x in [0...brick.extent.x] by 1
        for z in [0...brick.extent.z] by 1
          pushNeighborBrick('top', neighbors, x + brick.position.x,
            brick.position.y - 1, z + brick.position.z)

    # Bottom
    if brick.position.y + brick.extent.y < @layout.extent.y
      for x in [0...brick.extent.x] by 1
        for z in [0...brick.extent.z] by 1
          pushNeighborBrick('bottom', neighbors, x + brick.position.x,
            brick.position.y + brick.extent.y, z + brick.position.z)

    neighbors['topbottom'].push n for n in neighbors['top']
    neighbors['topbottom'].push n for n in neighbors['bottom']

    neighbors['leftright'].push n for n in neighbors['left']
    neighbors['leftright'].push n for n in neighbors['right']

    # --------------------
    # TODO: Looks like it can be refactored
    # --------------------
    # Push all top neighbors of top neighbors (second top neighbors of brick)
    neighbors['top2'].push n for n in neighbors['top']
    for n in neighbors['top']
      if n.position.y > 0
        for x in [0...n.extent.x] by 1
          for z in [0...n.extent.z] by 1
            pushNeighborBrick('top2', neighbors, x + n.position.x,
              n.position.y - 1, z + n.position.z)

    # Push all left neighbors of left neighbors (second left neighbors of brick)
    neighbors['left2'].push n for n in neighbors['left']
    for n in neighbors['left']
      if n.position.x > 0
        for y in [0...n.extent.y] by 1
          for z in [0...n.extent.z] by 1
            pushNeighborBrick('left2', neighbors, n.position.x - 1,
              y + n.position.y, z + n.position.z)

    # Push all right neighbors of right neighbors (second right neighbors of
    # brick)
    neighbors['right2'].push n for n in neighbors['right']
    for n in neighbors['right']
      if n.position.x + n.extent.x < @layout.extent.x
        for y in [0...n.extent.y] by 1
          for z in [0...n.extent.z] by 1
            pushNeighborBrick('right2', neighbors, n.position.x + n.extent.x,
              y + n.position.y, z + n.position.z)

    # Push all bottom neighbors of bottom neighbors (second bottom neighbors of
    # brick)
    neighbors['bottom2'].push n for n in neighbors['bottom']
    for n in neighbors['bottom']
      if n.position.y + n.extent.y < @layout.extent.y
        for x in [0...n.extent.x] by 1
          for z in [0...n.extent.z] by 1
            pushNeighborBrick('bottom2', neighbors, x + n.position.x,
              n.position.y + n.extent.y, z + n.position.z)

    return neighbors


  isLegalMerge: (brick, neighborBricks) ->
    if not neighborBricks? or neighborBricks.length == 0
      return false

    # Collect all slot positions
    pos = brick.slots
    for b in neighborBricks
      pos = pos.concat b.slots

    # Find width depth and height of the possibly merged brick
    xMin = xMax = pos[0][0]
    yMin = yMax = pos[0][1]
    zMin = zMax = pos[0][2]
    for [x,y,z] in pos
      xMin = x if x < xMin
      yMin = y if y < yMin
      zMin = z if z < zMin

      xMax = x if x > xMax
      yMax = y if y > yMax
      zMax = z if z > zMax

    width = xMax - xMin + 1
    depth = yMax - yMin + 1
    height = zMax - zMin + 1

    # Check for legal brick
    if width * depth * height == pos.length and # Filter out non-cubes
      @layout.bricksystem.get_BrickType(width, depth, height)
        # TODO: Consider available brick counts
        return true

    return false


  merge: (brick, neighborBricks) ->
    # Merge all neighborBricks into brick

    for b in neighborBricks
      brick.slots = brick.slots.concat b.slots

      # Change b-slots to brick-slots
      for [x,y,z] in b.slots
        @layout.grid[x][y][z] = brick

      b.slots = null # used to mark this brick as not available anymore

      # Remove b from all bricks
      @layout.all_bricks.splice(@layout.all_bricks.indexOf(b), 1)

      if @debugging
        b.remove_SceneModel()

      # Update brick graph
      for id, l of b.lowerBricks
        delete l.upperBricks[b.id]
        if id != brick.id
          l.upperBricks[brick.id] = brick
          brick.lowerBricks[id] = l

      for id, u of b.upperBricks
        delete u.lowerBricks[b.id]
        if id != brick.id
          u.lowerBricks[brick.id] = brick
          brick.upperBricks[id] = u

      #`delete b`
      'delete b'

    # Update position and extent
    xMin = xMax = brick.slots[0][0]
    yMin = yMax = brick.slots[0][1]
    zMin = zMax = brick.slots[0][2]
    for [x,y,z] in brick.slots
      xMin = x if x < xMin
      yMin = y if y < yMin
      zMin = z if z < zMin

      xMax = x if x > xMax
      yMax = y if y > yMax
      zMax = z if z > zMax

    brick.position = new Vector3D(xMin, yMin, zMin)
    brick.extent = new Vector3D(xMax - xMin + 1, yMax - yMin + 1,
      zMax - zMin + 1)
    brick.update_Bricktype()

    return brick


  resetToBasicBricks: (brick, keepHeight) ->
    # Remove brick in graph
    for id, l of brick.lowerBricks
      delete l.upperBricks[brick.id]
    for id, u of brick.upperBricks
      delete u.lowerBricks[brick.id]

    @layout.all_bricks.splice(@layout.all_bricks.indexOf(brick), 1)

    splitBricks = []
    if keepHeight
      # Add 1x1xheight bricks
      for [x,y] in brick.get_XY_Slots()
        newBrick = @layout.add_BasicBrick_with_Height(x,y,brick.position.z,
          brick.extent.z)

        if @debugging
          newBrick.update_SceneModel()

        splitBricks.push(newBrick)
    else
      # Add 1x1x1 bricks
      for [x,y,z] in brick.slots
        newBrick = @layout.add_BasicBrick_for(x,y,z)

        if @debugging
          newBrick.update_SceneModel()

        splitBricks.push(newBrick)


    # Setup graphs
    for b in splitBricks
      pos = b.position
      uBrick = @layout.get_Brick(pos.x, pos.y, pos.z + b.extent.z)
      if uBrick?
        b.upperBricks[uBrick.id] = uBrick
        uBrick.lowerBricks[b.id] = b

      lBrick = @layout.get_Brick(pos.x, pos.y, pos.z - 1)
      if lBrick?
        b.lowerBricks[lBrick.id] = lBrick
        lBrick.upperBricks[b.id] = b

    if @debugging
      brick.remove_SceneModel()

    #`delete brick`
    'delete brick'

    return splitBricks

module.exports = BrickLayouter
