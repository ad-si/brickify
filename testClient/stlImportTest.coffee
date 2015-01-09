StlImport = require '../src/plugins/stlImport'

describe 'stl import tests', () ->
	models = []
	for own file, hash of window.__karma__.files
		if /\.stl$/.test(file)
			models.push(file)


	for name in models
		it 'should import stl file ' + name, (done) ->
				readFile name, (fileContent) ->
					optimizedModel = new StlImport().importFile(name, fileContent)
					threeGeometry = optimizedModel.convertToThreeGeometry()
					expect(threeGeometry).not.to.be.null
					done()

readFile = (filename, callBack) ->
	xmlhttp = new XMLHttpRequest()
	xmlhttp.onreadystatechange = ->
		if xmlhttp.readyState == 4
			txt = xmlhttp.responseText
			callBack(txt)
	xmlhttp.open('GET', filename, true)
	xmlhttp.send()
