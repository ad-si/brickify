module.exports.trackEvent = (category, action,
	name = null, numericValue = null) ->
	if _paq?
		_paq.push(
			['trackEvent', category, action, name, numericValue]
		)

module.exports.setCustomSessionVariable = (slot, name, content) ->
	if _paq?
		_paq.push(
			['setCustomVariable', slot, name, content, 'visit']
		)
