wizardLogicInitialized = false
currentWizardStep = 0
wizardSteps = [
	'#wizardStepIntro'
	'#wizardStepStuds'
	'#wizardStepHoles'
	'#wizardStepFinished'
]
wizardFadeTime = 300

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

# Initializes the logic for the test strip wizard
initializeWizard = ($modal) ->
	# Bind all jQuery Elements, hide everything
	$wizardButtons = $modal.find('#wizardButtons')
	$nextButton = $wizardButtons.find('#wizardNext')
	$backButton = $wizardButtons.find('#wizardBack')
	$wizardButtons.hide()

	$startWizard = $modal.find('#startWizard')

	$wizardStepObjects = []
	for selector in wizardSteps
		$wizardStep = $modal.find(selector)
		$wizardStep.hide()
		$wizardStepObjects.push $wizardStep

	$sizeSelect = $modal.find('#sizeSelect')
	$legoContent = $modal.find('#legoContent')
	$stlContent = $modal.find('#stlContent')

	disableWizard = () ->
		$sizeSelect.fadeIn wizardFadeTime
		$legoContent.fadeIn wizardFadeTime
		$stlContent.fadeIn wizardFadeTime
		$wizardButtons.fadeOut wizardFadeTime
		currentWizardStep = 0

	applyCurrentWizardStep = () ->
		if currentWizardStep == wizardSteps.length or
		currentWizardStep == -1
			# Finish wizard
			# ToDo apply values from wizard selections here
			disableWizard()
		else
			$wizardStepObjects[currentWizardStep]
			.fadeIn wizardFadeTime

	# Bind button logic
	$nextButton.click () ->
		$wizardStepObjects[currentWizardStep]
		.fadeOut wizardFadeTime, () ->
			currentWizardStep++
			applyCurrentWizardStep()

	$backButton.click () ->
		$wizardStepObjects[currentWizardStep]
		.fadeOut wizardFadeTime, () ->
			currentWizardStep--
			applyCurrentWizardStep()

	# Fade out size select, start wizard on click
	$startWizard.click () ->
		currentWizardStep = 0
		$legoContent.fadeOut wizardFadeTime
		$stlContent.fadeOut wizardFadeTime
		$sizeSelect.fadeOut wizardFadeTime, () ->
			$wizardStepObjects[0].fadeIn wizardFadeTime
			$wizardButtons.fadeIn wizardFadeTime

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

	if not wizardLogicInitialized
		initializeWizard $modal

	return $modal

module.exports = getModal
