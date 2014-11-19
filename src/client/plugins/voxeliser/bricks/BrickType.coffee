Vector3D = require '../geometry/Vector3D'

class BrickType
	constructor: (@bricksystem, @width, @depth, @height) ->
		@available_Bricks = 100.000
		@model = @bricksystem.build_Brick( new Vector3D(0,0,0), new Vector3D(@width, @depth, @height) )

	get_SceneModel: () ->
		@model.get_SceneModel()

	get_Edge_SceneModel: () ->
		@model.get_Edge_SceneModel()

module.exports = BrickType