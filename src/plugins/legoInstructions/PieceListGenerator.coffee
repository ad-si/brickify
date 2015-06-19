log = require 'loglevel'
Brick = require '../newBrickator/pipeline/Brick'

# generates a list of how many bricks of which size
# is in the given set of bricks
module.exports.generatePieceList = (bricks) ->
	pieceList = []

	bricks.forEach (brick) ->
		for brickType in pieceList
			if Brick.isSizeEqual brickType.size, brick.getSize()
				brickType.count++
				return

		size = brick.getSize()
		brickType = {
			size: {
				x: Math.min size.x, size.y
				y: Math.max size.x, size.y
				z: size.z
			}
			count: 1
		}
		brickType.sizeIndex = Brick.getSizeIndex brickType.size
		pieceList.push brickType

	# sort bricks from small to big
	pieceList.sort (a,b) ->
		if a.size.x is b.size.x
			return a.size.y - b.size.y
		else
			return a.size.x - b.size.x

	return pieceList

module.exports.getHtml = (list, caption = true) ->
	html = ''

	if caption
		html = '<h3>Bricks needed</h3>'

	html +=
		'<p>To build this model you need the following bricks:' +
		'<style type="text/css">' +
		'.partListTable td{vertical-align:middle !important;}' +
		'</style>' +
		'<table class="table partListTable">' +
		'<tr><td><strong>Size</strong></td>' +
		'<td><strong>Type</strong></td>' +
		'<td><strong>Amount</strong></td>' +
		'<td><strong>Image</strong></td></tr>'

	for piece in list
		if piece.size.z == 1
			type = 'Plate'
		else if piece.size.z == 3
			type = 'Brick'
		else
			log.warn 'Invalid LEGO height for piece list'
			continue

		html +=
			'<tr>' +
			"<td>#{piece.size.x} x #{piece.size.y}</td>" +
			"<td>#{type}</td>" +
			"<td>#{piece.count}x</td>" +
			'<td><img src="img/partList/partList' +
			" (#{piece.sizeIndex + 1}).png\" height='40px'></td>" +
			'</tr>'

	html += '</table></p>'
	return html
