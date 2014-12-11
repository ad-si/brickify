module.exports = class Example

	init: (bundle) ->
		console.log 'Example Plugin initialization'

	init3d: (threejsNode) ->
		console.log 'Example Plugin initializes 3d'

	initUi: (domElements) ->
		console.log 'Example Plugin initializes UI'

	getUiSchema: () ->
		console.log('Example Plugin returns the UI schema.')

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
		}

	onStateUpdate: (state, done) ->
		console.log 'Exmaple Client Plugin state change'
		done()

	on3dUpdate: (timestamp) ->
		return undefined

	importFile: (fileName, fileContent) ->
		console.log 'Example Client Plugin imports a file'
		return undefined
