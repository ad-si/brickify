class BrickGroup
	constructor: (@brick_spaces = []) ->
		
		@color = new THREE.Color().setRGB(0.8, 0.8, 0.8)
		@color_ambient = new THREE.Color().setRGB(0.7, 0.7, 0.7)

		@opacity = 1.0
		@type = SelectType.custom
		@customBrick = null
		# sorry still need it for debugging
		#@color = get_BrickColor_group()

	is_all_Full_Bricks: () ->
		(space for space in @brick_spaces when space.is_full_Brick() ).length > 0

	get_BrickSpaces: -> @brick_spaces

	set_Custom_Brick: () ->
		for brick_space in @brick_spaces
			brick_space.set_Custom_Brick()

	set_Default_Brick: () ->
		for brick_space in @brick_spaces
			brick_space.set_Default_Brick()

	join: (otherBrickgroup) ->
		for space in otherBrickgroup.get_BrickSpaces()
			otherBrickgroup.remove_Space space
			@.add_Space space

	add_Space: (new_brick_space) ->
		if not @brick_spaces.includes new_brick_space
			for brick_space in @brick_spaces
				new_brick_space.dock_on brick_space
			new_brick_space.brickgroup = @
			@brick_spaces.add new_brick_space
		else
			console.log 'double added prevented'

	add_Spaces: (list) ->
		for item in list
			@.add_Space item


	remove_Space: (lost_brick_space) ->
		@brick_spaces.remove lost_brick_space
		for brick_space in @brick_spaces
			lost_brick_space.dock_off brick_space

		lost_brick_space.brickgroup = null
		lost_brick_space

	set_Opacity: (@opacity) ->
		if @scene_Model
			if @opacity < 1
				@scene_Model.material.transparent = true
			else
				@scene_Model.material.transparent = false
			@scene_Model.material.opacity = @opacity

	change_Color_to: ( r, g, b) ->
		@color.r = r / 255
		@color.g = g / 255
		@color.b = b / 255
		@scene_Model.material.color = @color
		@scene_Model.material.ambient = @color

	get_Polygons: () ->
		@polygons = []
		for brick_space in @brick_spaces
			@polygons = @polygons.concat brick_space.get_Polygons()
		@polygons

	update_SceneModel: () ->
		if @scene_Model
			parent = @scene_Model.parent
			if parent
				parent.remove @scene_Model
				parent.add @scene_Model = @.build_SceneModel()
			else
				@scene_Model = null

	remove_SceneModel: () ->
		@scene_Model.parent.remove(@scene_Model) if @scene_Model?
		@scene_Model = null

	get_SceneModel: () ->
		@scene_Model ?= @.build_SceneModel()

	build_SceneModel: () ->
		material = new THREE.MeshPhongMaterial( { vertexColors: THREE.FaceColors, color: @color, ambient: @color, wireframe: false} )
		geometry = new THREE.Geometry()

		polygons = @.get_Polygons()

		vertices_buffer_index = 0

		to_Three_Vector = (v) ->
			vec = new THREE.Vector3(v.x, v.y, v.z)

		for polygon in polygons
			faces = polygon.get_RenderFaces()
			faces_points = polygon.get_Points_of_RenderFace()

			for face, position in faces
				points = faces_points[position]
				geometry.vertices.add( to_Three_Vector points[0])
				geometry.vertices.add( to_Three_Vector points[1])
				geometry.vertices.add( to_Three_Vector points[2])
				face.a = vertices_buffer_index
				face.b = vertices_buffer_index + 1
				face.c = vertices_buffer_index + 2
				vertices_buffer_index += 3
				geometry.faces.add face
				
		geometry.mergeVertices()
		geometry.computeFaceNormals()

		mesh = new THREE.Mesh(geometry, material)
		mesh.brick = @
		mesh.selectType = SelectType.brick
		mesh.type = SelectType.custom
		mesh

module.exports = BrickGroup