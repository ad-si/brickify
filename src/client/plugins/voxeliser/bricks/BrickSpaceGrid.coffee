class BrickSpaceGrid
  constructor: (boundaryBox, @bricksystem) ->
    @scene_model = null
    @space = boundaryBox.clone()
    @space.align_to @bricksystem
    # extend border by one
    @space.minPoint.remove(@bricksystem.dimension)
    @space.maxPoint.add(@bricksystem.dimension)

    @position = @space.minPoint
    @extend = @space.get_Extent()

    @brick_position = @position.divide_by @bricksystem.dimension
    @brick_position.addScalar 1
    @brick_extend = @extend.divide_by(@bricksystem.dimension).round(0)
    @brick_extend.addScalar 1

    @all_bricks = []
    @outer_Bricks = []
    @inner_Bricks = []

    @grid = new Array(@brick_extend.x)

    for x in [0..@brick_extend.x]
      @grid[x] = new Array(@brick_extend.y)

      for y in [0..@brick_extend.y]
        @grid[x][y] = new Array(@brick_extend.z)
        @grid[x][y].range = {bricks: [], minZ: null, maxZ: null}

  set_Color: (@color) ->
    return

  update_Inner_Relation: () ->
    @outer_Bricks = []
    @inner_Bricks = []

    for brickspace in @all_bricks
      brickspace.set_Grid @

      if neighbor = @.get_BrickSpace brickspace.x + 1, brickspace.y, brickspace.z
        brickspace.set_Neighbor_for '+x', neighbor
      if neighbor = @.get_BrickSpace brickspace.x - 1, brickspace.y, brickspace.z
        brickspace.set_Neighbor_for '-x', neighbor
      if neighbor = @.get_BrickSpace brickspace.x, brickspace.y + 1, brickspace.z
        brickspace.set_Neighbor_for '+y', neighbor
      if neighbor = @.get_BrickSpace brickspace.x, brickspace.y - 1, brickspace.z
        brickspace.set_Neighbor_for '-y', neighbor
      if neighbor = @.get_BrickSpace brickspace.x, brickspace.y, brickspace.z + 1
        brickspace.set_Neighbor_for '+z', neighbor
      if neighbor = @.get_BrickSpace brickspace.x, brickspace.y, brickspace.z - 1
        brickspace.set_Neighbor_for '-z', neighbor

      if brickspace.inner
        @inner_Bricks.add brickspace
      else
        @outer_Bricks.add brickspace


  build_Cutting_Model_for: (brickSpace) ->
    position = new Vector3D( brickSpace.x, brickSpace.y, brickSpace.z)
    position.add @brick_position
    position.addScalar -1

    flat = no
    if not brickSpace.get_Side_for('-z').neighbor
      flat = yes

    extend = new Vector3D(1,1,1)
    @bricksystem.build_Brick_for position, extend, flat


  get_BrickSpace: (x,y,z) ->
    if 0 <= x < @brick_extend.x and 0 <= y < @brick_extend.y and 0 <= z < @brick_extend.z
      @grid[x][y][z]
    else
      console.warn 'Grid: Out of Range'
      undefined

  get_BrickSpace_global_for: (x,y,z) ->
    x -= @brick_position.x
    y -= @brick_position.y
    z -= @brick_position.z
    @.get_BrickSpace_for x, y, z

  get_BrickSpace_for: (x,y,z) ->
    if 0 <= x < @brick_extend.x and 0 <= y < @brick_extend.y and 0 <= z < @brick_extend.z
      space = @grid[x][y][z]
      space = @.create_BrickSpace_for(x,y,z) if space == undefined
      space
    else
      console.warn 'Grid: Out of Range'
      undefined

  create_BrickSpace_for: (x,y,z) ->
    brick = new BrickSpace(@bricksystem,x,y,z)
    @grid[x][y][z] = brick
    @all_bricks.push brick
    z_range = @grid[x][y].range
    z_range.bricks.push brick
    if !z_range.minZ? or z < z_range.minZ
      z_range.minZ = z
    if !z_range.maxZ? or z > z_range.maxZ
      z_range.maxZ = z
    brick


  get_SceneModel: () ->
    @scene_model ?= @build_SceneModel()

  build_SceneModel: () ->
    mesh = new THREE.Mesh()
    mesh.position = @position

    for brick in @all_bricks
      mesh.add brick.get_SceneModel()
    mesh


module.exports = BrickSpaceGrid
