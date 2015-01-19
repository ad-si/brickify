module.exports = class BrickArray
  constructor: (grid) ->
    @data = []
    @grid = grid
    @initializeForGrid(grid)
    return

  initializeForGrid: (grid) =>
    for z in [0..grid.numVoxelsZ - 1] by 1
      @data[z] ?= []
      for x in [0..grid.numVoxelsX - 1] by 1
        @data[z][x] ?= []
        for y in [0..grid.numVoxelsY - 1] by 1
          @data[z][x][y] = {id: -1}

  availableBrickSizes: () ->
    return [
      [1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],
      [2,2,1],[2,3,1],[2,4,1],[2,6,1],[2,8,1],[2,10,1],
      [1,1,3],[1,2,3],[1,3,3],[1,4,3],
      [1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3]
      [2,2,3],[2,3,3],[2,4,3],[2,6,3],[2,8,3],[2,10,3]
    ]





