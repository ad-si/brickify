module.exports = class BrickArray
  constructor: (grid) ->
    @data = []
    @grid = grid
    @initializeForGrid(grid)
    return

  initializeForGrid: (grid) =>
    for z in [0..grid.numVoxelsZ - 1] by 1
      for x in [0..grid.numVoxelsX - 1] by 1
        for y in [0..grid.numVoxelsY - 1] by 1
          if grid.zLayers[z]?[x]?[y]?
            if grid.zLayers[z][x][y] != false
              @initializeBrickPosition x, y, z

  initializeBrickPosition: (x, y, z) =>
    if not @data[z]
      @data[z] = []
    if not @data[z][x]
      @data[z][x] = []

    if not @data[z][x][y]?
      @data[z][x][y] = {id: 0}
    else
      #if the brick already exists, push new data to existing array
     console.warn 'visiting brick at x=#{x} y=#{y} z=#{z}'

  availableBrickSizes: () ->
    return [
      [1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],
      [2,2,1],[2,3,1],[2,4,1],[2,6,1],[2,8,1],[2,10,1],
      [1,1,3],[1,2,3],[1,3,3],[1,4,3],
      [1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3]
      [2,2,3],[2,3,3],[2,4,3],[2,6,3],[2,8,3],[2,10,3]
    ]





