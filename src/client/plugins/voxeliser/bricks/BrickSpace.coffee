class BrickSpace
  constructor: (@bricksystem, @x, @y, @z, @default_Brick = yes) ->
    @grid = null
    @default = no
    @pre_model = new Object3D()
    @inner = no
    @brickgroup = null

    @cutted = no

    @above_Brickspace = null
    @below_Brickspace = null
    @sides = []
    @sides_lookup = {}
    @side_labels = ['+x','-x','+y','-y','+z','-z']
    for label in @side_labels
      @sides_lookup[label] = side = {}
      @sides.add side
      side.label = label
      side.neighbor = null
      side.joined = no
      side.outsidePolygon = []
      side.onCutPolygon = []
      side.insidePolygon = []
      side.current_polygons = []
    @cut_polygons = []

    
    #color = new THREE.Color( Math.random() * 0xDDDDDD)
    #@full_model = new THREE.Mesh(geo, new THREE.MeshLambertMaterial( {color: color, ambient: color} ))
    #@full_model.position.x = @x * @bricksystem.width
    #@full_model.position.y = @y * @bricksystem.depth
    #@full_model.position.z = @z * @bricksystem.height

  ###
  create_Polygon_by: (points, original_polygon) ->
    edges = []
    last = points[points.length-1]

    for point in points
      edge = @get_Edge(last, point)
      edges.push edge
      last = point

    @add_Polygon new Polygon points, plane, edges
  ###

  build_All_Sides: () ->
    if @pre_model.polygons.length == 0
      @.build_Default_Model()
    else
      @.build_Compose_Model()
    @.updateSides()

  build_Default_Model: () ->
    unless @cutted
      full_brick = @grid.build_Cutting_Model_for @
      @sort_Inner_Sides full_brick.polygons.clone()
      @cutted = yes


  get_Side_for: (side_label) ->
    @sides_lookup[side_label]

  build_Compose_Model: () ->
    unless @cutted
      full_brick = @grid.build_Cutting_Model_for @

      cut_polygons = @pre_model.polygons.clone()
      if neighbor = @sides_lookup['+z'].neighbor
        cut_polygons = cut_polygons.concat neighbor.pre_model.polygons

      #original_cut_polygons = []
      #for polygon in cut_polygons
      #  parent = polygon.tag.original_polygon
      #  original_cut_polygons.add_unique parent

      #cut_polygons = original_cut_polygons

      brick_tree = BspTree.build_Tree full_brick.polygons
      cutting_tree = BspTree.build_Tree cut_polygons

      results = cutting_tree.split_Polygons full_brick.polygons

      @sort_Outer_Sides results[0]
      @sort_Inner_Sides results[1]
      @sort_OnCut_Sides results[2]

      #for polygon in results[1]
      #  cut.copy_foreign_Polygon polygon
      #for polygon in results[2]
      #  cut.copy_foreign_Polygon polygon

      results = brick_tree.split_Polygons cut_polygons
      window.r = results
      @cut_polygons = results[1]
      for polygon in @cut_polygons
        polygon.set_Object @

      @cutted = yes
    @
      #for polygon in @cut_polygons
      #  cut.copy_foreign_Polygon polygon

  sort_Inner_Sides: (polygons) ->
    for polygon in polygons
      side_label = polygon.tag.side
      side = @sides_lookup[side_label]
      side.insidePolygon.add polygon
      polygon.set_Object @
      polygon.side_label = side_label
    @

  sort_OnCut_Sides: (polygons) ->
    for polygon in polygons
      side_label = polygon.tag.side
      side = @sides_lookup[side_label]
      side.onCutPolygon.add polygon
      polygon.set_Object @
      polygon.side_label = side_label
    @

  sort_Outer_Sides: (polygons) ->
    for polygon in polygons
      side_label = polygon.tag.side
      if side_label not in @side_labels
        debugger
      side = @sides_lookup[side_label]
      side.outsidePolygon.add polygon
      polygon.set_Object @
      polygon.side_label = side_label
    @

  set_Grid: (@grid) ->
    return
  set_Neighbor_for: (label, brickspace) ->
    @sides_lookup[label].neighbor = brickspace

  get_Neighbor_for: (label) ->
    @sides_lookup[label].neighbor

  is_Neighbor: (brickspace) ->
    found = no
    for side in @sides
      found = yes if side.neighbor == brickspace
    found

  get_Neighbor_Side: (brickspace) ->
    neighbor_side = null
    for side in @sides
      if side.neighbor is brickspace
        neighbor_side = side
    neighbor_side

  get_SceneModel: () ->
    @full_model

  updateSides: () ->
    for side in @sides
      @updateSide side

  updateSide: (side) ->
    if side.joined
      if @default and !side.neighbor.default
        side.current_polygons = side.outsidePolygon
      else
        side.current_polygons = side.onCutPolygon
    else
      if @default
        side.current_polygons = side.insidePolygon.concat( side.outsidePolygon, side.onCutPolygon )
      else
        side.current_polygons = side.insidePolygon.concat( side.onCutPolygon )

  dock_on: (neighborSpace) ->
    side = @.get_Neighbor_Side(neighborSpace)
    if side
      if not side.joined
        @join_Side side, neighborSpace
        neighborSpace.dock_on @


  dock_off: (neighborSpace) ->
    side = @.get_Neighbor_Side(neighborSpace)
    if side
      if side.joined
        @seperate_Side side
        neighborSpace.dock_off @

  neighbor_side: (brickSpace) ->
    dx = brickSpace.x - @x
    dy = brickSpace.y - @y
    dz = brickSpace.z - @z
    
    switch
      when dx ==  1 and dy ==  0 and dz ==  0 then '+x'
      when dx == -1 and dy ==  0 and dz ==  0 then '-x'
      when dx ==  0 and dy ==  1 and dz ==  0 then '+y'
      when dx ==  0 and dy == -1 and dz ==  0 then '-y'
      when dx ==  0 and dy ==  0 and dz ==  1 then '+z'
      when dx ==  0 and dy ==  0 and dz == -1 then '-z'
      else null

  join_Side: (side, neighborSpace) ->
    unless side.joined
      #side.neighbor = neighborSpace
      side.joined = on
      @updateSide side

  seperate_Side: (side) ->
    if side.joined
      side.joined = off
      #side.neighbor = null
      @updateSide side

  get_Polygons: () ->
    @updateSides()
    polygons = []
    polygons = @cut_polygons unless @default
    polygons = polygons.concat(
        @sides_lookup['+x'].current_polygons,
        @sides_lookup['-x'].current_polygons,
        @sides_lookup['+y'].current_polygons,
        @sides_lookup['-y'].current_polygons,
        @sides_lookup['+z'].current_polygons,
        @sides_lookup['-z'].current_polygons)

  module.exports = BrickSpace

