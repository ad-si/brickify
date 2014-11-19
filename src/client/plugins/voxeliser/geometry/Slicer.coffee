BoundaryBox = require './BoundaryBox'
BrickGroup = require '../Bricks/BrickGroup'
BrickSpace = require '../Bricks/BrickSpace'

#require LegoGrid !?!


class Slicer
	constuctor: () ->
		return

	transform_to_Grid: (obj, ref_point) ->
		spaces = @cut_Object obj
		#console.log spaces[0]
		#console.log JSON.stringify(spaces)
		dim = @get_Dimensions spaces

		legoGrid = new LegoGrid(dim.x, dim.z, dim.y)

		for space in spaces
			layer = legoGrid.get_Layer space.y
			bg = new BrickGroup()
			bg.add_space space

			brick = layer.place_1x1_Brick_at(space.x, space.z)
			brick.set_BrickGroup bg
			brick.update_SceneModel()

		legoGrid

	get_Dimensions: (all_spaces) ->
		x = 0
		y = 0
		z = 0
		for space in all_spaces
			x = Math.max(x, space.x)
			y = Math.max(y, space.y)
			z = Math.max(z, space.z)

		{x: x + 1, y: y + 1, z: z + 1}

	cut_Object: (obj, ref_point) ->
		box = BoundaryBox.create_from(obj)
		spaces = box.lego_align().voxelize_to()

		cutting_cubes = new LegoGrid(spaces[0][0].length, spaces[0].length, spaces.length)

		all_BrickSpaces = []

		for y in [0...spaces.length]
			layer = cutting_cubes.get_Layer(y)
			for z in [0...spaces[y].length]
				for x in [0...spaces[y][z].length]
					cut = spaces[y][z][x].build_Lego().split_inside_outside( obj )
					if cut.csg.polygons.length > 0
						space = new BrickSpace(cut.csg, x, y, z)
						#space.set_Custom_Brick() #if y == 0
						all_BrickSpaces.push space

		all_BrickSpaces

	create_Voxels_for: (space) ->
		voxels = []
		for z in [space.minZ...space.maxZ]
			for y in [space.minY...space.maxY]
				for x in [space.minX...space.maxX]
					voxels.push [x,y,z]

	calculate_Space: (box, ref_point) ->
		space = new BoundaryBox()

module.exports = Slicer
