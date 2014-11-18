#<< app/modules/Bricks/BrickLayouter



# Represent a classical Brick of the Bricksystem
ids = 0

class Brick
	constructor: (@layout, @bricksystem, @position, @extend) ->
		@id = ids++
		@.update_Bricktype()

		@scene_Model = null
		r = Math.random()
		@default_color = null
		@default_color_ambient = null
		@color = new THREE.Color()
		@color_ambient = new THREE.Color()

		# Used by Layouter
		@upperBricks = {}
		@lowerBricks = {}

		@hidden = no
		@type = SelectType.brick

		@slots = []
		for x in [0...@extend.x] by 1
			for y in [0...@extend.y] by 1
				for z in [0...@extend.z] by 1
					@slots.push [@position.x + x, @position.y + y, @position.z + z]

	get_BrickSpace_Extend: (x,y,z) ->
		@layout.brickSpaceGrid.get_BrickSpace(@position.x + x, @position.y + y, @position.z + z)

	get_all_BrickSpaces: () ->
		brickspaces = []
		for x in [0...@extend.x] by 1
			for y in [0...@extend.y] by 1
				for z in [0...@extend.z] by 1
					brickspaces.add @.get_BrickSpace_Extend x,y,z
		brickspaces

	get_XY_Slots: ->
		slots = []
		for x in [0...@extend.x] by 1
			for y in [0...@extend.y] by 1
				slots.push [x + @position.x, y + @position.y]
		slots

	update_Bricktype: ->
		@bricktype = @bricksystem.get_BrickType @extend.x, @extend.y, @extend.z


	get_connected_Bricks: () ->
		@.get_upper_connected_Bricks().concat @.get_lower_connected_Bricks()

	get_upper_connected_Bricks: () ->
		connections = ( brick for id, brick of @upperBricks )

	get_lower_connected_Bricks: () ->
		connections = ( brick for id, brick of @lowerBricks )

	hide_SceneModel: () ->
		if @scene_Model
			@parent = @scene_Model.parent
			@parent.remove @scene_Model
			@hidden = yes

	show_SceneModel: () ->
		if @scene_Model and @parent
			@parent.add @scene_Model
			@hidden = no

	remove_SceneModel: () ->
		return null unless @scene_Model

		@parent = @scene_Model.parent
		if @parent
			@parent.remove @scene_Model
			@parent = null

	update_SceneModel: () ->
		return null unless @scene_Model

		parent = @scene_Model.parent
		if parent
			parent.remove @scene_Model
			parent.add @scene_Model = @.build_SceneModel()
		else
			@scene_Model = null

	get_SceneModel: () ->
		@scene_Model ?= @.build_SceneModel()
		@scene_Model

	set_Default_Color: (colorPalette) ->
		@default_color ?= colorPalette.get_Variation_of_Base 0.1
		@default_color_specular ?= colorPalette.get_Variation_of_Base 0.1

		@.set_Color @default_color, @default_color_specular

	highlight_Brick: (colorPalette) ->
		selected = colorPalette.get_Variation_of_Color colorPalette.selected, 0.1
		selected_specular = colorPalette.get_Variation_of_Color colorPalette.selected, 0.1
		@.set_Color selected, selected_specular

	set_Color: (color, specular) ->
		@color.set( color )
		@color_ambient.set( specular )
		if @scene_Model
			@scene_Model.material.color = @color
			@scene_Model.material.ambient = @color_ambient
		@.update_Color()

	update_Color: () ->
		@scene_model.geometry.colorsNeedUpdate = yes if @scene_model

	build_SceneModel: () ->
		#material = new THREE.MeshLambertMaterial({color:0xffffff * Math.random(),wireframe:false})
		material = new THREE.MeshPhongMaterial( { color: @color, ambient: @color_ambient } )
		geometry = @bricktype.get_SceneModel().geometry
		#geometry = new THREE.SphereGeometry(3)

		mesh = new THREE.Mesh(geometry, material)
		mesh.brick = @
		mesh.selectType = SelectType.brick

		delta = 0
		if @extend.x > @extend.y
			mesh.rotateZ(-Math.PI / 2)
			delta = @extend.y
		mesh.position.x  = @position.x * @bricksystem.width
		mesh.position.y  = (@position.y + delta) * @bricksystem.depth
		mesh.position.z  = @position.z * @bricksystem.height


		edge_material = new THREE.LineBasicMaterial( { color: new THREE.Color( 0x000000 ), linewidth: 1.2, wireframe: true, type: THREE.LinePieces} )
		edge_geometry = @bricktype.get_Edge_SceneModel().children.first().geometry
		edge_lines = new THREE.Line(edge_geometry, edge_material)
		edge_lines.type = THREE.LinePieces

		mesh.add edge_lines
		mesh


		###
		pos = @position.clone().multiply @bricksystem.dimension
		obj = @bricksystem.build_Brick(pos, @extend)
		obj.get_SceneModel()
		###

module.exports = Brick
