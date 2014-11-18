# BoundaryBox = require '../geometry/BoundaryBox'
# BspNode = require '../geometry/BspNode'
# BspTree = require '../geometry/BspTree'
# Edge = require '../geometry/Edge'
# Mesh = require '../geometry/Mesh'
# Object3D = require '../geometry/Object3D'
# Plane = require '../geometry/Plane'
# Point = require '../geometry/Point'
# Polygon = require '../geometry/Polygon'
# Ray = require '../geometry/Ray'
# Slicer = require '../geometry/Slicer'
SolidObject3D = require '../geometry/SolidObject3D'
# Tag = require '../geometry/Tag'
Vector3D = require '../geometry/Vector3D'

# Brick = require './Brick'
# BrickGrid = require './BrickGrid'
# BrickGroup = require './BrickGroup'
# BrickInstruction = require './BrickInstruction'
# BrickLayout = require './BrickLayout'
# BrickLayouter = require './BrickLayouter'
# BrickSpace = require './BrickSpace'
# BrickSpaceGrid = require './BrickSpaceGrid'
# BrickSystem = require './BrickSystem'
# BrickSystems = require './BrickSystems'
BrickType = require './BrickType'
# CustomBrick = require './CustomBrick'
# IterationInstruction = require './IterationInstruction'

class BrickSystem
  constructor: (@width, @depth, @height, @knob_height, @knob_radius) ->

    @dimension = new Vector3D(@width, @depth, @height)
    @knob_circle_steps = 15 # 360/30 = 12
    @brick_types = []
    @brick_type_lookup = []

  add_BrickTypes: (list) ->
    for type in list
      @.add_BrickType type[0], type[1], type[2]

  add_BrickType: (width, depth, height) ->
    type = new BrickType(@, width, depth, height)
    @brick_types.push type
    @brick_type_lookup[width] = [] unless @brick_type_lookup[width]
    @brick_type_lookup[depth] = [] unless @brick_type_lookup[depth]

    @brick_type_lookup[width][depth] = [] unless @brick_type_lookup[width][depth]
    @brick_type_lookup[depth][width] = [] unless @brick_type_lookup[depth][width]

    @brick_type_lookup[width][depth][height] = type
    @brick_type_lookup[depth][width][height] = type
    type

  get_BrickType: (width, depth, height) ->
    if @brick_type_lookup[width] and @brick_type_lookup[width][depth]
        return @brick_type_lookup[width][depth][height]
    return undefined

  build_Brick_for: (brick_position, extend, flat) ->
    position = brick_position.multiple_by @dimension
    @.build_Brick position, extend, flat

  build_Brick: (position, extend, flat = no) ->
    object = new SolidObject3D()
    #sides
    @.add_Brick_Sides object, position, extend
    for x in [0...extend.x] by 1         #caps
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, @height * (extend.z - 1) )
        @.add_Brick_top_Cap_to object, position.plus delta
    for x in [0...extend.x] by 1         #bottom
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, 0 )
        @.add_Brick_bottom_Plate_to object, position.plus(delta), flat
    for x in [0...extend.x] by 1         #top plates
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, @height * (extend.z - 1) )
        @.add_Brick_top_Plate_to object, position.plus delta
    for x in [0...extend.x] by 1         #bottom cap
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, 0 )
        @.add_Brick_bottom_Cap_to object, position.plus(delta), flat
    for x in [0...extend.x] by 1         #top sides
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, @height * (extend.z - 1) )
        @.add_Brick_top_Cap_Sides_to object, position.plus delta
    for x in [0...extend.x] by 1         #bottom sides
      for y in [0...extend.y] by 1
        delta = new Vector3D( @width * x, @depth * y, 0 )
        @.add_Brick_bottom_Cap_Sides_to object, position.plus(delta), flat
    object

  add_Brick_Sides: (object, position, extend) ->
    normal_xp = object.get_Normal 1,0,0
    normal_xn = object.get_Normal -1,0,0
    normal_yp = object.get_Normal 0,1,0
    normal_yn = object.get_Normal 0,-1,0

    for y in [0...extend.y] by 1
      for z in [0...extend.z] by 1
        @.add_Brick_Side object, position.plus(new Vector3D((extend.x - 1) * @width, y * @depth, z * @height) ), normal_xp
        @.add_Brick_Side object, position.plus(new Vector3D(0, y * @depth, z * @height) ), normal_xn

    for x in [0...extend.x] by 1
      for z in [0...extend.z] by 1
        @.add_Brick_Side object, position.plus(new Vector3D( x * @width, (extend.y - 1) * @depth, z * @height) ), normal_yp
        @.add_Brick_Side object, position.plus(new Vector3D( x * @width, 0, z * @height) ), normal_yn


  add_Brick_Side: (object, position, normal) ->
    reverse = yes
    if normal.x == 1
      factor_x = 1
      reverse = no
    if normal.y == 1
      factor_y = 1
      reverse = no
    factor_x ?= 0
    factor_y ?= 0

    side_x = 1 if normal.x == 0
    side_x ?= 0
    side_y = 1 if normal.y == 0
    side_y ?= 0

    points = [ object.get_Point( factor_x * @width + side_x * @width + position.x, factor_y * @depth +                   position.y,            position.z),
               object.get_Point( factor_x * @width +                   position.x, factor_y * @depth + side_y * @depth + position.y,            position.z),
               object.get_Point( factor_x * @width +                   position.x, factor_y * @depth + side_y * @depth + position.y,  @height + position.z),
               object.get_Point( factor_x * @width + side_x * @width + position.x, factor_y * @depth +                   position.y,  @height + position.z) ]

    points.reverse() if reverse

    if normal.x == -1
      side = '-x'
    if normal.x == 1
      side = '+x'
    if normal.y == -1
      side = '-y'
    if normal.y == 1
      side = '+y'

    object.add_Polygon_for( points, normal, {origin: ['brick'], side: side} )

  add_Brick_top_Cap_to: (object, position) ->
    middle_point = new Vector3D(@width / 2, @depth / 2, @height).add position
    circle_cap = []

    for angle in [0...360] by @knob_circle_steps
      circle_cap.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z + @knob_height)

    object.add_Polygon_for( circle_cap, object.get_Normal(0, 0, 1), {origin: ['brick'], side: '+z', knob: yes} )


  add_Brick_top_Cap_Sides_to: (object, position) ->
    middle_point = new Vector3D(@width / 2, @depth / 2, @height).add position
    cap_side_faces = []

    circle_cap = []
    circle_top = []
    for angle in [0...360] by  @knob_circle_steps
      circle_cap.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z + @knob_height)
      circle_top.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z)

    last_cap_point = circle_cap[ circle_cap.length - 1 ]
    last_top_point = circle_top[ circle_top.length - 1 ]

    for index in [0...360 / @knob_circle_steps]
      cap_point = circle_cap[index]
      top_point = circle_top[index]

      points = [ top_point, cap_point, last_cap_point, last_top_point ]
      normal = object.get_Normal_for(top_point, cap_point, last_cap_point)

      object.add_Polygon_for( points, normal, {origin: ['brick'], side: '+z'})

      last_cap_point = cap_point
      last_top_point = top_point


  add_Brick_top_Plate_to: (object, position) ->
    middle_point = new Vector3D(@width / 2, @depth / 2, @height).add position
    point_per_segement = 360 / @knob_circle_steps / 4
    edge_points = [ object.get_Point( @width + position.x, @depth + position.y, @height + position.z) ,
                    object.get_Point(           position.x, @depth + position.y, @height + position.z) ,
                    object.get_Point(           position.x,          position.y, @height + position.z) ,
                    object.get_Point( @width + position.x,          position.y, @height + position.z) ]

    circle_points = []
    for angle in [0...360] by @knob_circle_steps
      circle_points.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z)
    circle_points.push circle_points.first()

    last_edge_point = edge_points[ edge_points.length - 1]
    last_point = circle_points.first()

    for edge_point, side in edge_points
      object.add_Polygon_for( [last_point, last_edge_point, edge_point] , object.get_Normal(0, 0, 1), {origin: ['brick'], side: '+z'} )

      for point in circle_points[side * point_per_segement + 1 .. (side + 1) * point_per_segement ]
        object.add_Polygon_for( [ edge_point, point, last_point ], object.get_Normal( 0, 0, 1), {origin: ['brick'], side: '+z'} )
        last_point = point

      last_edge_point = edge_point


  add_Brick_bottom_Cap_to: (object, position, flat) ->
    unless flat
      middle_point = new Vector3D(@width / 2, @depth / 2, @knob_height).add position
      circle_cap = []

      for angle in [0...360] by @knob_circle_steps
        circle_cap.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z)
      circle_cap.reverse()

      object.add_Polygon_for( circle_cap, object.get_Normal(0, 0, -1), {origin: ['brick'], side: '-z', knob: yes} )


  add_Brick_bottom_Cap_Sides_to: (object, position, flat) ->
    unless flat
      middle_point = new Vector3D(@width / 2, @depth / 2, 0).add position
      cap_side_faces = []

      circle_cap = []
      circle_top = []
      for angle in [0...360] by @knob_circle_steps
        circle_cap.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z + @knob_height)
        circle_top.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z)
      circle_cap.reverse()
      circle_top.reverse()

      last_cap_point = circle_cap[ circle_cap.length - 1 ]
      last_top_point = circle_top[ circle_top.length - 1 ]

      for index in [0...360 / @knob_circle_steps]
        cap_point = circle_cap[index]
        top_point = circle_top[index]

        points = [ top_point, cap_point, last_cap_point, last_top_point ]
        normal = object.get_Normal_for(top_point, cap_point, last_cap_point)

        object.add_Polygon_for( points, normal, {origin: ['brick'], side: '-z'})

        last_cap_point = cap_point
        last_top_point = top_point


  add_Brick_bottom_Plate_to: (object, position, flat) ->
    middle_point = new Vector3D(@width / 2, @depth / 2, 0).add position
    point_per_segement = 360 / @knob_circle_steps / 4
    edge_points = [ object.get_Point( @width + position.x, @depth + position.y, position.z) ,
                    object.get_Point(           position.x, @depth + position.y, position.z) ,
                    object.get_Point(           position.x,          position.y, position.z) ,
                    object.get_Point( @width + position.x,          position.y, position.z) ]

    unless flat
      circle_points = []
      for angle in [0...360] by @knob_circle_steps
        circle_points.push object.get_Point( middle_point.x + Math.cos(angle * Math.PI / 180.0) * @knob_radius , middle_point.y + Math.sin(angle * Math.PI / 180.0) * @knob_radius, middle_point.z)
      circle_points.push circle_points.first()

      last_edge_point = edge_points[ edge_points.length - 1]
      last_point = circle_points.first()

      for edge_point, side in edge_points
        object.add_Polygon_for( [last_point, edge_point, last_edge_point] , object.get_Normal(0, 0, -1), {origin: ['brick'], side: '-z'} )

        for point in circle_points[side * point_per_segement + 1 .. (side + 1) * point_per_segement ]
          object.add_Polygon_for( [ edge_point, last_point, point ], object.get_Normal( 0, 0, -1), {origin: ['brick'], side: '-z'} )
          last_point = point

        last_edge_point = edge_point
    else
      object.add_Polygon_for( [ edge_points[3], edge_points[2], edge_points[1], edge_points[0] ], object.get_Normal( 0, 0, -1), {origin: ['brick'], side: '-z'})

module.exports = BrickSystem
