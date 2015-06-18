wizardLogicInitialized = false
currentWizardStep = 0
wizardSteps = [
	'#wizardStepIntro'
	'#wizardStepStuds'
	'#wizardStepHoles'
	'#wizardStepFinished'
]
wizardFadeTime = 300

#scoping variables
$sizeSelect = undefined
$legoContent = undefined
$stlContent = undefined
$wizardButtons = undefined
$wizardHoleSizeSelect = undefined
$wizardStudSizeSelect = undefined
$studSizeSelect = undefined
$holeSizeSelect = undefined

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

disableWizard = ->
	$sizeSelect.fadeIn wizardFadeTime
	$legoContent.fadeIn wizardFadeTime
	$stlContent.fadeIn wizardFadeTime
	$wizardButtons.fadeOut wizardFadeTime
	currentWizardStep = 0
# Initializes the logic for the test strip wizard
initializeWizard = ($modal) ->
	wizardLogicInitialized = true

	# Bind all jQuery Elements, hide everything
	$wizardButtons = $modal.find('#wizardButtons')
	$nextButton = $wizardButtons.find('#wizardNext')
	$nextButtonText = $nextButton.find('#text')
	$backButton = $wizardButtons.find('#wizardBack')
	$backButtonText = $backButton.find('#text')
	$calibrationSettings = $modal.find('#calibrationSettings')
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

	applyCurrentWizardStep = ->
		if currentWizardStep == wizardSteps.length or
		currentWizardStep == -1
			# Finish wizard

			# Apply data values
			studVal = $wizardStudSizeSelect.val()
			$studSizeSelect.find("option[value=#{studVal}]").attr('selected', true)
			holeVal = $wizardHoleSizeSelect.val()
			$holeSizeSelect.find("option[value=#{holeVal}]").attr('selected', true)

			# trigger intput event - so that
			# the selected settings get stored fpr csg
			$studSizeSelect.trigger 'input'
			$holeSizeSelect.trigger 'input'

			disableWizard()
		else
			$wizardStepObjects[currentWizardStep]
			.fadeIn wizardFadeTime

		# Update calibration preview on last step
		if currentWizardStep == wizardSteps.length - 1
			size = $wizardStudSizeSelect.find('option:selected').html()
			size += ' '
			size += $wizardHoleSizeSelect.find('option:selected').html()
			$calibrationSettings.html size

	updateButtonCaptions = ->
		if currentWizardStep == wizardSteps.length - 1
			$nextButtonText.html 'Finish'
		else
			$nextButtonText.html 'Next step'

		if currentWizardStep == 0
			$backButtonText.html 'Cancel wizard'
		else
			$backButtonText.html 'Go back'

	# Bind button logic
	$nextButton.click ->
		$wizardStepObjects[currentWizardStep]
		.fadeOut wizardFadeTime, ->
			currentWizardStep++
			applyCurrentWizardStep()
			updateButtonCaptions()

	$backButton.click ->
		$wizardStepObjects[currentWizardStep]
		.fadeOut wizardFadeTime, ->
			currentWizardStep--
			applyCurrentWizardStep()
			updateButtonCaptions()

	# Fade out size select, start wizard on click
	$startWizard.click ->
		currentWizardStep = 0
		updateButtonCaptions()
		$legoContent.fadeOut wizardFadeTime
		$stlContent.fadeOut wizardFadeTime
		$sizeSelect.fadeOut wizardFadeTime, ->
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

		# Prefill select values
		$studSizeSelect = $modal.find '#studSizeSelect'
		$wizardStudSizeSelect = $modal.find '#wizardStudSizeSelect'
		addOptions $studSizeSelect, steps, 0, alphabeticalList
		addOptions $wizardStudSizeSelect, steps, 0, alphabeticalList

		$holeSizeSelect = $modal.find '#holeSizeSelect'
		$wizardHoleSizeSelect = $modal.find '#wizardHoleSizeSelect'
		addOptions $holeSizeSelect, steps, 0, numericalList
		addOptions $wizardHoleSizeSelect, steps, 0, numericalList
	else
		$modal.find('#testStripContent').hide()

	if not wizardLogicInitialized
		initializeWizard $modal

	# Reset wizard when closing the modal
	$modal.on 'hidden.bs.modal', ->
		disableWizard()

	return $modal

module.exports = getModal
