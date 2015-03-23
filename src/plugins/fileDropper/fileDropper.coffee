module.exports.init = (callback) ->
	target = document.body
	overlay = addOverlay(target)
	bindDropHandler(target, overlay, callback)

addOverlay = (target) ->
	overlay = document.createElement('div')
	overlay.className = 'modal-backdrop'
	overlay.id = 'dropoverlay'
	overlay.style.display = 'none'
	overlay.innerHTML = '<div id="dropborder">
										<div id="dropinfo" class="text-center">drop here</div>
										</div>'
	target.appendChild overlay
	return overlay

bindDropHandler = (target, overlay, callback) ->
	target.addEventListener 'drop',
		(event) ->
			hideOverlay(overlay)
			callback event
	target.addEventListener 'dragover',
		(event) ->
			ignoreEvent(event)
			showOverlay(overlay)
	target.addEventListener 'dragleave',
			(event) ->
				ignoreEvent(event)
				hideOverlay(overlay)

showOverlay = (overlay) ->
	overlay.style.display = 'block'

hideOverlay = (overlay) ->
	overlay.style.display = 'none'

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()
