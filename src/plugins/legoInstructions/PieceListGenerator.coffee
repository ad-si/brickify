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
		pieceList.push {
			size: {
				x: size.x
				y: size.y
				z: size.z
			}
			count: 1
		}

	# sort so that most needed bricks are on top
	pieceList.sort (a,b) ->
		return b.count - a.count

	# switch sizes so that the smallest number
	# is always first
	for piece in pieceList
		if piece.size.x > piece.size.y
			tmp = piece.size.x
			piece.size.x = piece.size.y
			piece.size.y = tmp

	return pieceList

module.exports.getHtml = (list) ->
	html = '<h3>Bricks needed</h3>'
	html += '<p>This is a list of how many and what types of'
	html += ' bricks you need to build this model:'
	html += '<table>'
	html += '<tr><td><strong>Amount</strong></td>'
	html += '<td><strong>Type</strong></td>'
	html += '<td><strong>Size</strong></td></tr>'
	for piece in list
		if piece.size.z == 1
			type = 'Plate'
		else if piece.size.z == 3
			type = 'Brick'
		else
			log.warn 'Invalid LEGO height for piece list'
			continue

		html += '<tr>'
		html += "<td>#{piece.count}x</td>"
		html += "<td>#{type}</td>"
		html += "<td>#{piece.size.x} x #{piece.size.y}</td>"
		html += '</tr>'

	html += '</table></p>'
	return html
