module.exports = class Brick
  constructor: (@position, @size) ->
    console.log 'creating brick'
    @upperSlots = []
    @lowerSlots = []

    for xx in [0..@size.x-1] by 1
      @upperSlots[xx] = []
      @lowerSlots[xx] = []
      for yy in [0..@size.y-1] by 1
        @upperSlots[xx][yy] = {}
        @lowerSlots[xx][yy] = {}

    @initializeSlots()

    return

  initializeSlots: () =>
    return

  availableBrickSizes: () =>
    return [
      [1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],
      [2,2,1],[2,3,1],[2,4,1],[2,6,1],[2,8,1],[2,10,1],
      [1,1,3],[1,2,3],[1,3,3],[1,4,3],
      [1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3]
      [2,2,3],[2,3,3],[2,4,3],[2,6,3],[2,8,3],[2,10,3]
    ]





