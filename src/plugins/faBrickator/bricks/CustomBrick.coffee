BrickGroup = require './BrickGroup'

class CustomBrick
	constructor: () ->
		@brickgroup = new BrickGroup()
		@brickgroup.customBrick = @
		@model = null
		@selection = null

	set_Model: (@model) ->
		return

	get_Model: () ->
		@model

	update_SceneModel: () ->
		@brickgroup.update_SceneModel()

	get_SceneModel: () ->
		@brickgroup.get_SceneModel()

	get_Polygons: () ->
		@brickgroup.get_Polygons()

	check_for_Broken_Bricks: () ->
		checked = []
		all_spaces = @brickgroup.get_BrickSpaces()
		working_list = all_spaces.clone()

		for space in working_list
			space

module.exports = CustomBrick
