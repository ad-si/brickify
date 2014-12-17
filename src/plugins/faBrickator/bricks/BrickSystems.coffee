BrickSystem = require './BrickSystem'
BrickType = require './BrickType'

# Lego ------------------------------------------
class BrickSystems
  #2.510 definitely works but is still a bit tight, 2.505 is to small
  Lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
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
      model = bricksystem.build_Brick( p , new Vector3D(type.width, type.depth,
                                                        type.height) )
      editor.iteration_Manager.model_dropped model

module.exports = BrickSystems
