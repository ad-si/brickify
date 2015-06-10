addOptions = ($select, range, defaultValue) ->
	for i in [-range..range]
		$select.append($('<option/>').attr('value', i).text(i))
	$select.val defaultValue


getModal = ({testStrip: testStrip, stl: stl, lego: lego, steps: steps}) ->
	html = '
<div id=\"downloadModal\" tabindex=\"-1\" class=\"modal fade\">
    <div class=\"modal-dialog\">
      <div class=\"modal-content\">
        <div class=\"modal-header\">
          <button data-dismiss=\"modal\" class=\"close\">&#215;</button>
          <h4 class=\"modal-title disabled\">Download</h4>
        </div>
        <div class=\"modal-body\">'
	if testStrip
		html += '
    <h4 class=\"disabled\">Download stl for 3d printer</h4>
    <p>Select the stud size that works best for your 3d printer. If you don\'t
know the size, download and print the&nbsp;
<a  href=\"/download/testStrip.zip\">test strip</a>.</p>
    <center>
        <img src=\"/img/testStrip.png\" width=\"300\" />
    </center>
<p>To connect LEGO studs into the test strip, this size works best:
    <select id=\"holeSizeSelect\" class=\"form-control\"/>
</p>
<p>To connect test strip studs into LEGO bricks, this size works best:
    <select id=\"studSizeSelect\" class=\"form-control\"/>
</p>
<br />'

	if  stl
		html += '
<div id=\"stlDownloadButton\" class=\"btn btn-success btn-block disabled\">
    &nbsp;&nbsp;Download stl for 3D printer
</div>'
	if lego
		html += '
<h4 class=\"disabled\">Download Instructions</h4>
<div id=\"downloadInstructionsButton\"
class=\"btn btn-success btn-block disabled\">
    &nbsp;&nbsp;Download LEGO instructions and scad file
</div>'
	html += '
</div>
<div class=\"modal-footer\">
    <button data-dismiss=\"modal\" class=\"btn btn-primary disabled\">
        Close
    </button>
</div>
</div></div></div>'

	$modal = $($.parseHTML html)
	if testStrip
		$studSizeSelect = $modal.find '#studSizeSelect'
		addOptions $studSizeSelect, steps, 0
		$holeSizeSelect = $modal.find '#holeSizeSelect'
		addOptions $holeSizeSelect, steps, 0

	return $modal

module.exports = getModal
