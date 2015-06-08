log = require 'loglevel'

# generates a list of how many bricks of which size
# is in the given set of bricks
module.exports.generatePartList = (bricks) ->
	partList = []

	bricks.forEach (brick) ->
		for brickType in partList
			if equalSize brickType.size, brick.getSize()
				brickType.count++
				return

		partList.push {
			size: brick.getSize()
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

equalSize = (a,b) ->
	return ((a.x == b.x and a.y == b.y) or
		(a.x == b.y and a.y == b.x)) and a.z == b.z

module.exports.getHtml = (list) ->
	html = '<h3>Bricks needed</h3>'
	html += '<p>This is a list of how many and what types of'
	html += ' bricks you need to build this model: <ul>'

	for part in list
		html += '<li>'
		html += "<strong>#{part.count}x</strong> "
		if part.size.z == 1
			html += 'Plates with size '
		else if part.size.z == 3
			html += 'Bricks with size '
		else
			log.warn 'Invalid LEGO heigth for part list'

		html += "#{part.size.x} x #{part.size.y}</li>"

	html += '</ul></p>'
	return html
