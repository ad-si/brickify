alphabeticalList = (i, range) ->
	# A = 65
	return String.fromCharCode 65 + (range + i)

numericalList = (i, range) ->
	return range + i + 1

addOptions = ($select, range, defaultValue, listFunction) ->
	for i in [-range..range]
		caption = listFunction(i, range)
		$select.append $('<option/>').attr('value', i).text(caption)
	$select.val defaultValue

getModal = ({testStrip: testStrip, stl: stl, lego: lego, steps: steps}) ->
	$modal = $('#downloadModal')

	if lego
		$modal.find('#legoContent').show()
	else
		$modal.find('#legoContent').hide()

	if stl
		$modal.find('#stlContent').show()
	else
		$modal.find('#stlContent').hide()

	if testStrip
		$modal.find('#testStripContent').show()
		$studSizeSelect = $modal.find '#studSizeSelect'
		addOptions $studSizeSelect, steps, 0, alphabeticalList
		$holeSizeSelect = $modal.find '#holeSizeSelect'
		addOptions $holeSizeSelect, steps, 0, numericalList
	else
		$modal.find('#testStripContent').hide()

	return $modal

module.exports = getModal
