BrickSystem = require './BrickSystem'
BrickType = require './BrickType'

# Lego ------------------------------------------
class BrickSystems
  Lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512) #2.510 definitely works but is still a bit tight, 2.505 is to small
  Lego.add_BrickTypes [
    [1,1,1],
    [1,2,1],
    [1,3,1],
    [1,4,1],
    [1,6,1],
    [1,8,1],
    [2,2,1],
    [2,3,1],
    [2,4,1],
    [2,6,1],
    [2,8,1],
    [2,10,1],

    [1,1,3],
    [1,2,3],
    [1,3,3],
    [1,4,3],
    [1,6,3],
    [1,8,3],
    [1,10,3],
    [1,12,3],
    [1,16,3],
    [2,2,3],
    [2,3,3],
    [2,4,3],
    [2,6,3],
    [2,8,3],
    [2,10,3]
  ]

  # Lego Plates ------------------------------------------

  LegoPlate = new BrickSystem( 8, 8, 3.2, 1.7, 2.5)
  LegoPlate.add_BrickTypes [
    [1,1,1], [1,2,1], [1,3,1], [1,4,1], [1,6,1], [1,8,1],
    [2,2,1], [2,3,1], [2,4,1], [2,6,1], [2,8,1], [2,10,1]
  ]


  # Lego Normal Bricks ------------------------------------------

  LegoBrick = new BrickSystem( 8, 8, 9.6, 1.7, 2.5)
  LegoBrick.add_BrickTypes [
    [1,1,1],
    [1,2,1],
    [1,3,1],
    [1,4,1],
    [1,6,1],
    [1,8,1],
    [2,2,1],
    [2,3,1],
    [2,4,1],
    [2,6,1],
    [2,8,1],
    [2,10,1]
  ]

  # Nano Blocks -----------------------------------------------

  NanoBlock = new BrickSystem( 4, 4, 3, 1.75, 1.25)
  NanoBlock.add_BrickTypes [
    [1,1,1],  [1,2,1],  [1,3,1],  [1,4,1],  [1,6,1],  [1,8,1],
    [2,2,1],  [2,3,1],  [2,4,1],  [2,6,1],  [2,8,1],  [2,10,1]
  ]

  # Nano Block Plus-----------------------------------------------

  NanoBlockPlus = new BrickSystem( 6, 6, 6, 1.5, 1.5)
  NanoBlockPlus.add_BrickTypes [
    [1,1,1],  [1,2,1],  [1,3,1],  [1,4,1],  [1,6,1],  [1,8,1],
    [2,2,1],  [2,3,1],  [2,4,1],  [2,6,1],  [2,8,1],  [2,10,1]
  ]

  # Dia Block -----------------------------------------------

  DiaBlock = new BrickSystem( 8, 8, 6, 3.5, 2.5)
  DiaBlock.add_BrickTypes [
    [1,1,1],  [1,2,1],  [1,3,1],  [1,4,1],  [1,6,1],  [1,8,1],
    [2,2,1],  [2,3,1],  [2,4,1],  [2,6,1],  [2,8,1],  [2,10,1]
  ]


  # Duplo Block -----------------------------------------------


  Duplo = new BrickSystem( 16, 16,  19.2, 4.7, 4.65)
  Duplo.add_BrickTypes [
    [1,1,1], [1,2,1], [2,2,1],  [2,4,1],  [2,6,1]
  ]


  # Lunimatic Construction Blocks

  LunaBlock = new BrickSystem( 95, 95, 115, 20, 30)
  LunaBlock.add_BrickTypes [
    [1,1,1],  [1,2,1], [1,3,1], [1,4,1], [2,2,1], [2,4,1]
  ]

  show_all = (bricksystem) ->
    p = new Vector3D(-150,0,0 )
    for type in bricksystem.brick_types
      p = p.plus(new Vector3D(20,0,0 ))
      model = bricksystem.build_Brick( p , new Vector3D(type.width, type.depth, type.height) )
      editor.iteration_Manager.model_dropped model

  #Lego2.add_Brick_Sides o,p, new Vector3D(1,1,1)
  #Lego2.add_Brick_top_Cap_to o,p
  #Lego2.add_Brick_top_Cap_Sides_to o,p
  #Lego2.add_Brick_top_Plate_to o,p
  #Lego2.add_Brick_bottom_Cap_to o,p
  #Lego2.add_Brick_bottom_Cap_Sides_to o,p
  #Lego2.add_Brick_bottom_Plate_to o,p
  ###
  build_BrickVolume = (brickSystem) ->

    brick = new SolidObject3D()

    # building points
    points = [
          brick.get_Point(                  0,                  0,                  0 ),
          brick.get_Point( brickSystem.length,                  0,                  0 ),
          brick.get_Point( brickSystem.length, brickSystem.length,                  0 ),
          brick.get_Point(                  0, brickSystem.length,                  0 ),
          brick.get_Point(                  0,                  0, brickSystem.height ),
          brick.get_Point( brickSystem.length,                  0, brickSystem.height ),
          brick.get_Point( brickSystem.length, brickSystem.length, brickSystem.height ),
          brick.get_Point(                  0, brickSystem.length, brickSystem.height ) ]


    middle_point = { x: brickSystem.length/2, y: brickSystem.length/2, z: brickSystem.height/2 }

    circle_steps = 30

    circle_top = []
    for angle in [0...360] by circle_steps
      circle_top.push brick.get_Point( middle_point.x + Math.cos(angle*Math.PI/180.0) * brickSystem.knob_radius , middle_point.y + Math.sin(angle*Math.PI/180.0) * brickSystem.knob_radius, brickSystem.height)
    circle_top.push circle_top[0]

    circle_cap = []
    for angle in [0...360] by circle_steps
      circle_cap.push brick.get_Point( middle_point.x + Math.cos(angle*Math.PI/180.0) * brickSystem.knob_radius , middle_point.y + Math.sin(angle*Math.PI/180.0) * brickSystem.knob_radius, brickSystem.height + brickSystem.knob_height)
    circle_cap.push circle_cap[0]

    circle_bottom = []
    for angle in [360...0] by -circle_steps
      circle_bottom.push brick.get_Point( middle_point.x + Math.cos(angle*Math.PI/180.0) * brickSystem.knob_radius , middle_point.y + Math.sin(angle*Math.PI/180.0) * brickSystem.knob_radius, 0)
    circle_bottom.push circle_bottom[0]

    circle_inlet = []
    for angle in [360...0] by -circle_steps
      circle_inlet.push brick.get_Point( middle_point.x + Math.cos(angle*Math.PI/180.0) * brickSystem.knob_radius , middle_point.y + Math.sin(angle*Math.PI/180.0) * brickSystem.knob_radius, brickSystem.knob_height)
    circle_inlet.push circle_inlet[0]
    #build faces


    sides = [  [ [ points[0], points[4], points[7], points[3] ], brick.get_Normal(-1, 0, 0), {origin: ['brick'], side: '-x'} ],
               [ [ points[1], points[2], points[6], points[5] ], brick.get_Normal( 1, 0, 0), {origin: ['brick'], side: '+x'} ],
               [ [ points[0], points[1], points[5], points[4] ], brick.get_Normal( 0, 0,-1), {origin: ['brick'], side: '-y'} ],
               [ [ points[2], points[3], points[7], points[6] ], brick.get_Normal( 0, 0, 1), {origin: ['brick'], side: '+y'} ], ]



    point_per_segement = 360/circle_steps/4
    top_points = [points[6],points[7],points[4],points[5] ]

    bottom_points = [points[1],points[0],points[3],points[2] ]

    # knob faces

    top_faces = []
    cap_faces = []

    bottom_faces = []
    inlet_faces = []

    old_top_edge = points[5]
    old_bottom_edge = points[2]


    cap_top_face = [[ circle_cap, brick.get_Normal(0, 0, 1), {origin: ['brick'], side: '+z', knob: yes}]]
    inlet_bottom_face = [[ circle_inlet, brick.get_Normal(0, 0, -1), {origin: ['brick'], side: '-z', knob: yes}]]

    for side in [0...4]
      edge_top_point = top_points[side]
      edge_bottom_point = bottom_points[side]

      old_top_point = circle_top[ side * point_per_segement ]
      old_cap_point = circle_cap[ side * point_per_segement ]

      old_bottom_point = circle_bottom[ side * point_per_segement ]
      old_inlet_point = circle_inlet[ side * point_per_segement ]

      top_faces.push [ [ old_top_edge, edge_top_point , old_top_point ], brick.get_Normal( 0,1, 0), {origin: ['brick'], side: '+z'} ]
      bottom_faces.push [ [ old_bottom_edge, edge_bottom_point , old_bottom_point ], brick.get_Normal( 0,-1, 0) , {origin: ['brick'], side: '-z'}]

      for point in [side * point_per_segement + 1 .. (side+1) * point_per_segement]
        current_top_point = circle_top[point]
        current_cap_point = circle_cap[point]
        current_bottom_point = circle_bottom[point]
        current_inlet_point = circle_inlet[point]

        top_faces.push [ [ current_top_point, old_top_point, edge_top_point ], brick.get_Normal( 0, 1, 0), {origin: ['brick'], side: '+z'}]
        cap_faces.push [ [ current_top_point, current_cap_point, old_cap_point, old_top_point ], brick.get_Normal_for(current_top_point, current_cap_point, old_cap_point) , {origin: ['brick'], side: '+z'}]

        bottom_faces.push [ [ current_bottom_point, old_bottom_point, edge_bottom_point ], brick.get_Normal( 0, -1, 0), {origin: ['brick'], side: '-z'}]
        inlet_faces.push [ [ current_bottom_point, current_inlet_point, old_inlet_point, old_bottom_point ], brick.get_Normal_for(current_bottom_point, current_inlet_point, old_inlet_point) , {origin: ['brick'], side: '-z'}]


        old_top_point = circle_top[point]
        old_cap_point = circle_cap[point]
        old_bottom_point = circle_bottom[point]
        old_inlet_point = circle_inlet[point]

      old_top_edge = edge_top_point
      old_bottom_edge = edge_bottom_point

    faces.push [ circle_cap[0...circle_cap.length-1], brick.get_Normal( 0, 1, 0), {origin: ['lego'], side: '+y'} ]
    faces.merge bottom_faces
    faces.push [ circle_inlet[0...circle_inlet.length-1], brick.get_Normal( 0, 1, 0), {origin: ['lego'], side: '-y'} ]
    faces.merge top_faces

    faces.merge cap_faces
    faces.merge inlet_faces


    add_Sides = (obj, list) ->
      for item in list
        polygon = obj.add_Polygon_for( item[0], item[1] )
        #polygon.tag.merge_Labels( item[2] )

    # knovex hull
    add_Sides brick, sides
    add_Sides brick, cap_top_face
    add_Sides brick, bottom_faces

    # inner convex hull
    add_Sides brick, top_faces
    add_Sides brick, inlet_bottom_face

    # knobs
    add_Sides brick, cap_faces
    add_Sides brick, inlet_faces

    brick

  ###
  #Lego.atom_Brick = build_BrickVolume(Lego)

module.exports = BrickSystems
