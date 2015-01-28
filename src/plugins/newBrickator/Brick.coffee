module.exports = class Brick
  constructor: (@position, @size) ->
    # position always contains smalles x & smallest y

    #initialize slots
    @upperSlots = []
    @lowerSlots = []

    for xx in [0..@size.x - 1] by 1
      @upperSlots[xx] = []
      @lowerSlots[xx] = []
      for yy in [0..@size.y - 1] by 1
        @upperSlots[xx][yy] = false
        @lowerSlots[xx][yy] = false

    @neighbours = [[], [], [], []]
    return

  @availableBrickSizes: () =>
    return [
      [1, 1, 1], [1, 2, 1], [1, 3, 1], [1, 4, 1], [1, 6, 1], [1, 8, 1],
      [2, 2, 1], [2, 3, 1], [2, 4, 1], [2, 6, 1], [2, 8, 1], [2, 10, 1],
      [1, 1, 3], [1, 2, 3], [1, 3, 3], [1, 4, 3],
      [1, 6, 3], [1, 8, 3], [1, 10, 3], [1, 12, 3], [1, 16, 3]
      [2, 2, 3], [2, 3, 3], [2, 4, 3], [2, 6, 3], [2, 8, 3], [2, 10, 3]
    ]

  uniqueConnectedBricks: () =>
    upperBricks = @uniqueBricksInSlots @upperSlots
    lowerBricks = @uniqueBricksInSlots @lowerSlots
    return upperBricks.concat lowerBricks

  uniqueBricksInSlots: (upperOrLowerSlots) =>
    bricks = []
    for slotsX in upperOrLowerSlots
      for slotXY in slotsX
        if slotXY != false
          bricks.push slotXY
    return removeDuplicates bricks

  @isValidSize: (width, length, height) =>
    for validSize in Brick.availableBrickSizes()
      if validSize[0] == width and validSize[1] == length and
      validSize[2] == height
        return true
      if validSize[0] == length and validSize[1] == width and
      validSize[2] == height
        return true
    return false

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

