droptext = null

module.exports.init = (targetDomObject, text) ->
	bindDropHandler targetDomObject
	droptext = text

bindDropHandler = (target) ->
	console.log "Initialized dropper"
	target.on 'drop', onModelDrop
	target.on 'dragover', ignoreEvent
	target.on 'dragleave', ignoreEvent

onModelDrop = (event) ->
	event.preventDefault()
	event.stopPropagation()
	droptext.html('Uploading file  <img src="img/spinner.gif" style="height: 1.2em;">')

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()