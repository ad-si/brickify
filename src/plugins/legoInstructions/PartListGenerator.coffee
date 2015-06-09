log = require 'loglevel'
Brick = require '../newBrickator/pipeline/Brick'

# generates a list of how many bricks of which size
# is in the given set of bricks
module.exports.generatePartList = (bricks) ->
	partList = []

	bricks.forEach (brick) ->
		for brickType in partList
			if Brick.isSizeEqual brickType.size, brick.getSize()
				brickType.count++
				return

		size = brick.getSize()
		partList.push {
			size: {
				x: size.x
				y: size.y
				z: size.z
			}
			count: 1
		}

	# sort so that most needed bricks are on top
	partList.sort (a,b) ->
		return b.count - a.count

	# switch sizes so that the smallest number
	# is always first
	for part in partList
		if part.size.x > part.size.y
			tmp = part.size.x
			part.size.x = part.size.y
			part.size.y = tmp

	return partList

module.exports.getHtml = (list) ->
	html = '<h3>Bricks needed</h3>'
	html += '<p>This is a list of how many and what types of'
	html += ' bricks you need to build this model:'
	html += '<table>'
	html += '<tr><td><strong>Amount</strong></td>'
	html += '<td><strong>Part description</strong></td></tr>'
	for part in list
		html += '<tr><td>'
		html += "#{part.count}x</td><td>"
		if part.size.z == 1
			html += 'Plates with size '
		else if part.size.z == 3
			html += 'Bricks with size '
		else
			log.warn 'Invalid LEGO height for part list'

		html += "#{part.size.x} x #{part.size.y}</td></tr>"

	html += '</table></p>'
	return html
