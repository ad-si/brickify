expect = (chai && chai.expect) || require('chai').expect;

readFile = (filename, callBack) ->
	xmlhttp = new XMLHttpRequest()
	xmlhttp.onreadystatechange = ->
		if xmlhttp.readyState == 4
			txt = xmlhttp.responseText
			callBack(txt)
	xmlhttp.open("GET",filename,true)
	xmlhttp.send();

describe 'stl import tests', ->
	canvas = document.getElementById("canvas");
	it 'has a canvas', (done) ->
		expect(canvas).to.not.be.null
		done()

	it 'allows file reading', (done) ->
		xmlhttp = new XMLHttpRequest()
		xmlhttp.onreadystatechange = ->
			if xmlhttp.readyState == 4
				txt = xmlhttp.responseText
				expect(txt).to.equal('testfile')
				done()
		xmlhttp.open("GET","testfile_for_local_file_access.txt",true)
		xmlhttp.send();

	it 'imports stl', (done) ->
		readFile 'models/unit_cube.stl', (txt) ->
			file = new File([txt], 'unit_cube.stl')

			event = new MouseEvent('drop', {
				'view': window,
				'bubbles': true,
				'cancelable': true
			});
			#event.dataTransfer = 'test'#{files: [file]}
			#canvas.dispatchEvent(event)
			done()