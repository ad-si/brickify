class IterationInstructions

	constructor: (@iteration) ->
		@models = []
		@current_Model = null
		@current_Index = 0

	check_Instructions: () ->
		@models = @iteration.models
		#for model in @iteration.models
		#  model.get_Instructions()

	get_current_Instruction: () -> @current_Instruction

	get_Index: () -> @current_Index

	get_max_Models: () -> @models.length

	get_current_Model: () ->
		@current_Model = @models[@current_Index]

	get_next_Model: () ->
		@current_Index++ unless @current_Index >= @models.length - 1
		@current_Model = @models[@current_Index]

	get_previous_Model: () ->
		@current_Index-- unless @current_Index <= 0
		@current_Model = @models[@current_Index]


module.exports = IterationInstructions