!function () {

	var alertCallback = function() {
		return bootbox.alert({
			title: 'Download not available',
			message: 'We are sorry, but this is not yet available.' +
			' Please check back later</br></br>' +
			' Click the image on the left to load and edit the model.'
		});
	};

	$('.notImplemented').click(alertCallback);
}();
