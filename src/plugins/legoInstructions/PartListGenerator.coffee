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
	html += '<td><strong>Type</strong></td>'
	html += '<td><strong>Size</strong></td></tr>'
	for part in list
		if part.size.z == 1
			type = 'Plate'
		else if part.size.z == 3
			type = 'Brick'
		else
			log.warn 'Invalid LEGO height for part list'
			continue

		html += '<tr>'
		html += "<td>#{part.count}x</td>"
		html += "<td>#{type}</td>"
		html += "<td>#{part.size.x} x #{part.size.y}</td>"
		html += '</tr>'

	html += '</table></p>'
	return html
