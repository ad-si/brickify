fileLoader = require './fileLoader'

module.exports.init = (objects, callback) ->
	objects.each (i, el) -> bindChangeHandler(
		el
		callback
		objects
	)

bindChangeHandler = (el, callback, fileInputs) ->
	el.addEventListener 'change', (event) ->
		callback event
		fileInputs.val('')
