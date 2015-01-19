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
    if profiling
      console.log 'Step Layouting'
      start = new Date()

    @bricks = new BrickArray grid

    @countBricks grid

    for z in [1..grid.numVoxelsZ - 1] by 1
      if z % 2 is 0
        @layoutInXDirectionForLayer z
      else
        @layoutInYDirectionForLayer z

    if profiling
      elapsed = new Date() - start
      console.log "Step Layouting finished in #{elapsed}ms"

    return bricks

  layoutBottomLayer: (grid) =>

  ###
    for x in [0..grid.numVoxelsX - 1] by 1
      for y in [0..grid.numVoxelsY - 1] by 1
        if @bricks.data[0]?[x]?[y]?
          if @bricks.data[0][x][y] != false
            @bricks.data[0][x][y].id = @nextBrickIdx()
    return
  ###

  countBricks: (grid) =>
    for z in [0..grid.numVoxelsZ - 1] by 1
      for x in [0..grid.numVoxelsX - 1] by 1
        for y in [0..grid.numVoxelsY - 1] by 1
          if @bricks.data[z]?[x]?[y]?
            if @bricks.data[z][x][y] != false
              @bricks.data[z][x][y].id = @nextBrickIdx()
    console.log @bricks.data
    return

  layoutInXDirectionForLayer: (z) =>
    @layoutUnsopportedPositionsInLayer z
    return

  layoutInYDirectionForLayer: (z) =>
    @layoutUnsopportedPositionsInLayer z
    return

  layoutUnsopportedPositionsInLayer: (z) =>
    @bricks
    return

   