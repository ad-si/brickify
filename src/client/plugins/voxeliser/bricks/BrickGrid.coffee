class BrickGrid
  constructor: (boundaryBox, bricksystem) ->
    @space = boundaryBox.clone()
    @space.align_to bricksystem
    # increase border by one
    @space.minPoint.remove()
