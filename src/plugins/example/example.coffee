operative = require 'operative'

module.exports = class Example

	init: (bundle) ->
		console.log 'Example Plugin initialization'

	init3d: (threejsNode) ->
		console.log 'Example Plugin initializes 3d'

	getConvertUiSchema: () ->
		console.log('Example Plugin returns the UI schema.')

		actioncallback = () =>
			console.log 'Example Plugin performs an action!'
			@useWebWorker()

		return {
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

	useWebWorker: () =>
		console.log 'task setup'
		fibWorker = (fibN) ->
			console.log "operative #{fibN} start"
			deferred = @deferred()
			fib = (n) -> if n > 1 then fib(n - 1) + fib(n - 2) else 1
			dofib = do(fibN) -> ->
				if fibN <= 40
					deferred.fulfill fib(fibN)
				else
					deferred.reject "fib(#{fibN}) is too big for me!"
			setTimeout dofib, 2000

		longTask1 = operative(fibWorker)
		longTask2 = operative(fibWorker)

		console.log 'execute 40'
		longTask1(40)
			.then (res) -> console.log "fib(40) is #{res}"
			.catch (err) -> console.error err
		console.log 'execute 50'
		longTask2(50)
			.then (res) -> console.log "fib(50) is #{res}"
			.catch (err) -> console.error err
		console.log 'execution done'

	onStateUpdate: (state) ->
		console.log 'Example Client Plugin state change'

	on3dUpdate: (timestamp) ->
		return undefined

	importFile: (fileName, fileContent) ->
		console.log 'Example Client Plugin imports a file'
		return undefined
