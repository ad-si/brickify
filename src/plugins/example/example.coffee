module.exports = class Example

	init: (bundle) ->
		console.log 'Example Plugin initialization'

	init3d: (threejsNode) ->
		console.log 'Example Plugin initializes 3d'

	initUi: (domElements) ->
		console.log 'Example Plugin initializes UI'

	getUiSchema: () ->
		console.log('Example Plugin returns the UI schema.')

		actioncallback = () ->
			console.log 'Example Plugin performs an action!'

		return {
		title: 'Example Plugin'
		type: 'object'
		properties:
			size:
				description: 'Size of the elements'
				type: 'number'

			numberOfElements:
				description: 'Number of elements'
				type: 'number'
				minimum: 0

			color:
				description: 'Color in hex'
				type: 'string'
				format: 'color'

			items:
				type: 'string'
				enum: ['item 1', 'item 2', 'item 3']
		actions:
			a1:
				title: 'Action 1'
				callback: actioncallback
			a2:
				title: 'Action 2'
				type: 'danger'
				callback: actioncallback
		}

	uiEnabled: (node) ->
		console.log "Enabled Example Ui with node #{node.fileName}"

	uiDisabled: (node) ->
		console.log "Disabled Example Ui with node #{node.fileName}"

	onStateUpdate: (state) ->
		console.log 'Exmaple Client Plugin state change'

	on3dUpdate: (timestamp) ->
		return undefined

	importFile: (fileName, fileContent) ->
		console.log 'Example Client Plugin imports a file'
		return undefined
