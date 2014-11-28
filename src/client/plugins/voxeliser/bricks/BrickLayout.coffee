Brick = require './Brick'
Vector3D = require '../geometry/Vector3D'


class BrickLayout
  constructor: (@brickSpaceGrid) ->
    @bricksystem = @brickSpaceGrid.bricksystem
    @extend = @brickSpaceGrid.brick_extend
    @colorPalette = @brickSpaceGrid.colorPalette
    @model = null
    @all_bricks = []
    @grid = new Array(@extend.x)
    @is_layouted = no

    for x in [0..@extend.x]
      @grid[x] = new Array(@extend.y)

      for y in [0..@extend.y]
        @grid[x][y] = new Array(@extend.z)

    for b in @brickSpaceGrid.all_bricks
      @.add_BasicBrick_for(b.x, b.y, b.z)

  show_all_Bricks: () ->
    for brick in @all_bricks
      brick.show_SceneModel()

  hide_all_Bricks: () ->
    for brick in @all_bricks
      brick.hide_SceneModel()
    @

  get_BrickCount: () ->
    return @all_bricks.length

  get_BrickSpace: (x, y, z) ->
    @brickSpaceGrid.get_BrickSpace x, y, z

  get_Brick: (x, y, z) ->
    @grid[x][y][z]

  get_BricksOfLayer: (id) ->
    bricks = []

    for brick in @all_bricks
      for [x,y,z] in brick.slots
        if z == id
          bricks.push brick
          break

    bricks

  set_Model: (@model) ->
    return

  remove_Brick: (brick) ->
    @all_bricks.remove(brick)
    for [x,y,z] in brick.slots
      @grid[x][y][z] = null

    for id, upper of brick.upperBricks
      delete upper.lowerBricks[brick.id]
    for id, lower of brick.lowerBricks
      delete lower.upperBricks[brick.id]

    brick.remove_SceneModel()

  add_BasicBrick_by: (brickspace) ->
    brick = @.add_BasicBrick_for brickspace.x, brickspace.y, brickspace.z
    if @scene_Model
      brick.set_Default_Color @colorPalette
      @scene_Model.add brick.get_SceneModel()
      brick

  remove_Brick_by: (brickspace) ->
    brick = @.get_Brick brickspace.x, brickspace.y, brickspace.z
    if brick
      @.remove_Brick brick

  add_BasicBrick_for: (x,y,z) ->
    brick = new Brick(@, @bricksystem, new Vector3D(x,y,z), new Vector3D(1,1,1))
    @.add_Brick(brick, x, y, z)
    brick

  add_BasicBrick_with_Height: (x,y,z, height) ->
    brick = new Brick(@, @bricksystem,
      new Vector3D(x,y,z), new Vector3D(1,1,height))
    @.add_Brick(brick, x, y, z)

  add_Brick: (brick) ->
    @all_bricks.push brick
    for x in [0...brick.extend.x] by 1
      for y in [0...brick.extend.y] by 1
        for z in [0...brick.extend.z] by 1
          @grid[x + brick.position.x][y + brick.position.y][z +
            brick.position.z] = brick

    brick

  update_SceneModel: () ->
    parent = @scene_Model.parent
    if parent
      parent.remove @scene_Model
      parent.add @scene_Model = @.build_SceneModel()
    else
      @scene_Model = null

  get_SceneModel: () ->
    @scene_Model ?= @.build_SceneModel()
    @scene_Model

  show_StabilityView: () ->
    for brick in @.all_bricks
      conns = Object.keys(brick.upperBricks).length +
          bject.keys(brick.lowerBricks).length

      # Magic formula
      brickStability = Math.min(
        conns / (Math.ceil(Math.sqrt(brick.slots.length)) * 2), 1.0)

      color = new THREE.Color().setHSL 0.4 * brickStability, 0.55, 0.5
      ambient = new THREE.Color().setHSL 0.4 * brickStability, 0.6, 0.4

      brick.set_Color color, ambient

  restore_DefaultView: () ->
    for brick in @.all_bricks
      brick.set_Default_Color @colorPalette
      brick.update_SceneModel()

  build_SceneModel: () ->
    mesh = new THREE.Mesh()
    mesh.position = @brickSpaceGrid.position
    for brick in @all_bricks
      brick.set_Default_Color @colorPalette
      model =  brick.get_SceneModel()
      mesh.add model
      if brick.hidden
        brick.hide_SceneModel()
      ###l = geo.vertices.length
      for v in model.geometry.vertices
        v1 = model.position.clone().add(v)
        geo.vertices.push v1
      for f in model.geometry.faces
        a1 = l + f.a
        b1 = l + f.b
        c1 = l + f.c
        nf = new THREE.Face3(a1,b1,c1)
        geo.faces.push nf
      ###
    #geo.mergeVertices()
    #geo.computeFaceNormals()
    #console.log mesh
    mesh

  get_Statistics: ->
    stats = {}
    stats['Brick count'] = @all_bricks.length

    # Determine connections
    total = 0
    conns = {} # e.g. conns = {0:2, 1:20, 2:40, 3:23}
    for brick in @all_bricks
      connCount = Object.keys(brick.upperBricks).length +
          Object.keys(brick.lowerBricks).length
      total += connCount

      # Save for later
      if connCount not of conns
        conns[connCount] = 0
      conns[connCount] += 1

    avg = total / stats['Brick count']

    stats['Total connections'] = total
    stats['Connections per brick'] = avg

    # Mean deviation
    deviation = 0
    for numConnections, times of conns
      deviation += times * Math.abs(numConnections - avg)
    meanDeviation = deviation / stats['Brick count']

    stats['Mean deviation'] = meanDeviation
    stats['Details on connections'] = conns

    stats

module.exports = BrickLayout
