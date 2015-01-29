module.exports = class ObjectMover
	init: (@bundle) =>
		return
	init3d: (@threejsNode) =>
		return
	onStateUpdate: (state) =>
		return
	on3dUpdate: (timestamp) =>
		return
	getBrushes: ->
		return [{
			text: 'move'
			icon: 'move'
			clickCallback: -> console.log 'move-brush modifies scene (click)'
			moveCallback: -> console.log 'move-brush modifies scene (move)'
			selectCallback: -> console.log 'move-brush was selected'
			deselectCallback: -> console.log 'move-brush was deselected'
		}]
