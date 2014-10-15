var express = require('express'),
	app = express(),
	server


app.get('/', function (req, res) {
	res.send('Hello World!')
})

server = app.listen(3000, function () {

	var host = server.address().address,
		port = server.address().port

	console.log('Example app listening at http://%s:%s', host, port)
})
