fs = require 'fs'
meshlib = require '../index'

models = [
	'unitCube.ascii'
	'unitCube.bin'
	'gearwheel.ascii'
	'gearwheel.bin'
	'bunny.ascii'
	'bunny.bin'
]

for model in models
	do (model) ->
		fs.readFile "./#{model}.stl", (error, stlBuffer) ->

			if error
				throw error

			console.time(model)

			meshlib.parse stlBuffer, null, (error, data) ->
				if error
					throw error
				else if not data
					throw new Error 'Data is empty!'
				else
					console.timeEnd(model)
