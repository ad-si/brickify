fileLoader = require './fileLoader'

module.exports.init = (objects, feedbackTarget, finishedCallback) ->
	objects.each (i, el) -> bindChangeHandler(
		el
		feedbackTarget
		finishedCallback
		objects
	)

bindChangeHandler = (el, feedbackTarget, finishedCallback, fileInputs) ->
	callback = (event) ->
		fileLoader.onLoadFile(event, feedbackTarget, finishedCallback)
		fileInputs.val('')
	el.addEventListener 'change', callback
