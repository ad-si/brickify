fileLoader = require './fileLoader'

module.exports.init = (objects, feedbackTarget, finishedCallback) ->
	objects.each (i, el) -> bindDropHandler(el, feedbackTarget, finishedCallback)

bindDropHandler = (el, feedbackTarget, finishedCallback) ->
	el.addEventListener 'change',
		(event) -> fileLoader.onModelDrop(event, feedbackTarget, finishedCallback)
