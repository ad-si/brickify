BrickArray = require './BrickArray'

module.exports = class BrickLayouter
  constructor: () ->
    @nextBrickIndex = 0
    @bricks = null
    return

  nextBrickIdx: () =>
    temp = @nextBrickIndex
    @nextBrickIndex++
    return temp

  layoutForGrid: (grid, profiling = false) =>
    @bricks = new BrickArray grid

    if profiling
      console.log 'Step Layouting'
      start = new Date()

    @layoutBottomLayer grid
    for z in [1..grid.numVoxelsZ - 1] by 1
      if z % 2 is 0
        @layoutInXDirectionForLayer z
      else
        @layoutInYDirectionForLayer z

    if profiling
      stop = new Date() - start
      console.log "Step Layouting finished in #{stop}ms"

    return bricks

  layoutBottomLayer: (grid) =>
    for x in [0..grid.numVoxelsX - 1] by 1
      for y in [0..grid.numVoxelsY - 1] by 1
        if grid.zLayers[0]?[x]?[y]?
          if grid.zLayers[0][x][y] != false
            @bricks.data[0][x][y] = {id: @nextBrickIdx()}

    console.log @bricks.data
    return

  layoutInXDirectionForLayer: (z) =>
    layoutUnsopportedPositionsInLayer z
    return

  layoutInYDirectionForLayer: (z) =>
    layoutUnsopportedPositionsInLayer z
    return

  layoutUnsopportedPositionsInLayer: (z) =>
    return