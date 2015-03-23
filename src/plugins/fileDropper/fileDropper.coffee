module.exports.init = (objects, overlay, callback) ->
	objects.each (i, el) ->
		bindDropHandler(el, overlay, callback)

bindDropHandler = (target, overlay, callback) ->
	target.addEventListener 'drop',
		(event) ->
			hideOverlay(event, overlay)
			callback event
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
