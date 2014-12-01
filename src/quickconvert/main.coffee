#get model from url
hash = window.location.hash

if hash.indexOf('+error') < 0
	$('#importerrors').hide()
else
	#remove error note from hash
	hash = hash.substring 0, hash.length - 7

#remove '#'
hash = hash.substring 1,hash.length

#adjust links to editor according to model hash
vanillaLink = $('.applink').attr('href')
vanillaLink += 'initialModel=' + hash
$('.applink').attr('href', vanillaLink)
