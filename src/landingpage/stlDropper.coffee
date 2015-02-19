fileLoader = require './fileLoader'

module.exports.init = (objects, feedbackTarget, overlay, finishedCallback) ->
	objects.each (i, el) ->
		bindDropHandler(el, feedbackTarget, overlay, finishedCallback)

bindDropHandler = (target, feedbackTargets, overlay, finishedCallback) ->
	target.addEventListener 'drop',
		(event) ->
			hideOverlay(event, overlay)
			fileLoader.onModelDrop(event, feedbackTargets, finishedCallback)
		false
	target.addEventListener 'dragover',
		(event) -> showOverlay(event, overlay),
		false
	target.addEventListener 'dragleave',
			(event) -> hideOverlay(event, overlay),
			false

showOverlay = (event, overlay) ->
	ignoreEvent event
	overlay.show()

hideOverlay = (event, overlay) ->
	ignoreEvent event
	overlay.hide()

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()
