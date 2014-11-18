# BoundaryBox = require './BoundaryBox'
BspNode = require './BspNode'
# BspTree = require './BspTree'
# Edge = require './Edge'
# Mesh = require './Mesh'
# Object3D = require './Object3D'
# Plane = require './Plane'
# Point = require './Point'
# Polygon = require './Polygon'
# Ray = require './Ray'
# Slicer = require './Slicer'
SolidObject3D = require './SolidObject3D'
# Tag = require './Tag'
# Vector3D = require './Vector3D'

#require Lego?

class BspTree
	constructor: () ->
		@base_Node = null

	@build_Tree: (polygons) ->
		tree = new @
		return tree if !polygons.length

		tree.base_Node = new BspNode()
		tree.base_Node.build_Tree polygons.clone()

		tree

	split_Polygons: (polygons) ->
		before_polygons = []
		behind_polygons = []
		front_facing_coplanar = []
		back_facing_coplanar = []

		for polygon in polygons
			[ before, behind, front_coplanar, back_coplanar ] = @base_Node.covers_Polygon polygon
			before_polygons = before_polygons.concat before
			behind_polygons = behind_polygons.concat behind
			front_facing_coplanar = front_facing_coplanar.concat front_coplanar
			back_facing_coplanar = back_facing_coplanar.concat back_coplanar

		[before_polygons, behind_polygons, front_facing_coplanar, back_facing_coplanar]



	plot_Tree: () ->
		@base_Node.plot_Node(0)

	build_DebugModel: () ->
		model = new SolidObject3D()
		@base_Node.build_DebugModel model
		model

	build_DebugModel_Depth: (d) ->
		model = new SolidObject3D()
		@base_Node.build_DebugModel_Depth model, d
		model

nextInit = () ->
	window.model = editor.iteration_Manager.current_Iteration.models[0]
	window.model.remove_SceneModel()
	window.so = new SolidObject3D()
	editor.iteration_Manager.model_dropped(so)
	window.count = 0

nexttime = (n) ->
	for i in [0...n] by 1
		next()

next = () ->
	p = window.model.polygons[window.count ]
	window.so.copy_foreign_Polygon p
	window.so.update_SceneModel()
	window.count++
	editor.workspace.canvas.update()

test = () ->
	return


test12 = () ->
	window.m = Lego.brick_types[0].model
	window.a1 = new SolidObject3D()
	window.a1.color = ColorPalette.next()
	#window.m.remove_SceneModel()
	window.p = m.polygons
	window.t = BspTree.build_Tree(p)
	[window.before1, window.behind1, window.front_co1, window.back_co1] = window.t.split_Polygons( p )
	for polygon in window.front_co1
		window.a1.copy_foreign_Polygon polygon

	editor.iteration_Manager.model_dropped(a1)
	#for polygon in window.behind1
	#  window.a1.copy_foreign_Polygon polygon

old_test3 = () ->

	window.m = editor.iteration_Manager.current_Iteration.models[0].object3D

	window.b = editor.iteration_Manager.current_Iteration.models[1].object3D

	window.m.remove_SceneModel()
	window.b.remove_SceneModel()

	window.a1 = new SolidObject3D()
	window.a1.color = ColorPalette.next()

	window.a2 = new SolidObject3D()
	window.a2.color = ColorPalette.next()

	window.a3 = new SolidObject3D()
	window.a3.color = ColorPalette.next()

	window.t = BspTree.build_Tree(m.polygons)

	[window.before1, window.behind1, window.front_co1, window.back_co1] = window.t.split_Polygons( window.b.polygons )
	for polygon in window.behind1
		window.a1.copy_foreign_Polygon polygon


	window.t = BspTree.build_Tree(b.polygons)

	[window.before1, window.behind1, window.front_co1, window.back_co1] = window.t.split_Polygons( window.m.polygons )
	for polygon in window.behind1
		window.a2.copy_foreign_Polygon polygon
	for polygon in window.front_co1
		window.a3.copy_foreign_Polygon polygon

	editor.iteration_Manager.add( new Model(a1) )
	editor.iteration_Manager.add( new Model(a2) )
	editor.iteration_Manager.add( new Model(a3) )

old_test = () ->

	#window.m = Lego.brick_types[0].model
	#window.b = Lego.brick_types[0].model
	#window.b = Lego.build_Brick(new Vector3D(1,0,1), new Vector3D(1,1,1))

	window.m = editor.iteration_Manager.current_Iteration.models[0]

	#window.b = editor.iteration_Manager.current_Iteration.models[1]

	window.m.remove_SceneModel()
	#window.b.remove_SceneModel()



	console.log 'bsp'
	window.t = BspTree.build_Tree(m.polygons)
	window.mo = window.t.build_DebugModel()
	editor.iteration_Manager.model_dropped(window.mo)

	window.a1 = new SolidObject3D()
	window.a1.color = ColorPalette.next()
	#[window.before1, window.behind1, window.front_co1, window.back_co1] = window.t.split_Polygons( window.b.polygons )

	console.log 'cut'
	#for polygon in window.before1
	#  window.a1.copy_foreign_Polygon polygon
	#for polygon in window.front_co1
	#  window.a1.copy_foreign_Polygon polygon

	window.a2 = new SolidObject3D()
	window.a2.color = ColorPalette.green()

	#window.t = BspTree.build_Tree(b.polygons)
	#[window.before2, window.behind2, window.front_co2, window.back_co2] = window.t.split_Polygons(window.m.polygons)
	#for polygon in window.behind2
	#  window.a1.copy_foreign_Polygon polygon

	#window.a.copy_foreign_Polygon window.behind[0]
	#editor.iteration_Manager.model_dropped(a1)
	#editor.iteration_Manager.model_dropped(a2)

old_test_2 = () ->

	#window.m = Lego.brick_types[0].model
	#window.b = Lego.brick_types[0].model
	#window.b = Lego.build_Brick(new Vector3D(1,0,1), new Vector3D(1,1,1))

	window.m = editor.iteration_Manager.current_Iteration.models[0]

	#window.b = editor.iteration_Manager.current_Iteration.models[1]

	window.m.remove_SceneModel()
	#window.b.remove_SceneModel()


	console.log 'bsp'
	window.t = BspTree.build_Tree(m.polygons)
	window.mo = window.t.build_DebugModel_Depth 1
	editor.iteration_Manager.model_dropped(window.mo)

	window.a1 = new SolidObject3D()
	window.a1.color = ColorPalette.next()
	#[window.before1, window.behind1, window.front_co1, window.back_co1] = window.t.split_Polygons( window.b.polygons )

	console.log 'cut'
	#for polygon in window.before1
	#  window.a1.copy_foreign_Polygon polygon
	#for polygon in window.front_co1
	#  window.a1.copy_foreign_Polygon polygon

	window.a2 = new SolidObject3D()
	window.a2.color = ColorPalette.green()

	#window.t = BspTree.build_Tree(b.polygons)
	#[window.before2, window.behind2, window.front_co2, window.back_co2] = window.t.split_Polygons(window.m.polygons)
	#for polygon in window.behind2
	#  window.a1.copy_foreign_Polygon polygon

	#window.a.copy_foreign_Polygon window.behind[0]
	#editor.iteration_Manager.model_dropped(a1)
	#editor.iteration_Manager.model_dropped(a2)

test2 = () ->
	for n in [0...100] by 1
		test()

module.exports = BspTree
