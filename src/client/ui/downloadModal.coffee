addOptions = ($select, range, defaultValue) ->
	for i in [-range..range]
		$select.append($('<option/>').attr('value', i).text(i))
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
		addOptions $studSizeSelect, steps, 0
		$holeSizeSelect = $modal.find '#holeSizeSelect'
		addOptions $holeSizeSelect, steps, 0
	else
		$modal.find('#testStripContent').hide()

	return $modal

module.exports = getModal
