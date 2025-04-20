let wizardLogicInitialized = false
let currentWizardStep = 0
const wizardSteps = [
  "#wizardStepIntro",
  "#wizardStepStuds",
  "#wizardStepHoles",
  "#wizardStepFinished",
]
const wizardFadeTime = 300

// Scoping variables
let $modal = undefined
let $sizeSelect = undefined
let $legoContent = undefined
let $stlContent = undefined
let $testStripContent = undefined
let $wizardButtons = undefined
let $wizardHoleSizeSelect = undefined
let $wizardStudSizeSelect = undefined
let $studSizeSelect = undefined
let $holeSizeSelect = undefined

const alphabeticalList = (i, range) => // A = 65
  String.fromCharCode(65 + (range + i))

const numericalList = (i, range) => range + i + 1

const addOptions = function ($select, range, defaultValue, listFunction) {
  for (let i = -range, end = range, asc = -range <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
    const caption = listFunction(i, range)
    $select.append(
      $("<option/>")
        .attr("value", i)
        .text(caption),
    )
  }

  return $select.val(defaultValue)
}

const disableWizard = function () {
  $sizeSelect.fadeIn(wizardFadeTime)
  $legoContent.fadeIn(wizardFadeTime)
  $stlContent.fadeIn(wizardFadeTime)
  $wizardButtons.fadeOut(wizardFadeTime)
  return currentWizardStep = 0
}

// Initializes the logic for the test strip wizard
const initializeWizard = function ($modal) {
  wizardLogicInitialized = true

  // Bind all jQuery Elements, hide everything
  $wizardButtons = $modal.find("#wizardButtons")
  const $nextButton = $wizardButtons.find("#wizardNext")
  const $nextButtonText = $nextButton.find("#text")
  const $backButton = $wizardButtons.find("#wizardBack")
  const $backButtonText = $backButton.find("#text")
  const $calibrationSettings = $modal.find("#calibrationSettings")
  $wizardButtons.hide()

  const $startWizard = $modal.find("#startWizard")

  const $wizardStepObjects = wizardSteps.map((selector) => {
    const $wizardStep = $modal.find(selector)
    $wizardStep.hide()
    return $wizardStep
  })

  $sizeSelect = $modal.find("#sizeSelect")

  const applyCurrentWizardStep = function () {
    if ((currentWizardStep === wizardSteps.length) ||
    (currentWizardStep === -1)) {
      // Finish wizard

      // Apply data values
      const studVal = $wizardStudSizeSelect.val()
      $studSizeSelect
        .find(`option[value=${studVal}]`)
        .attr("selected", true)
      const holeVal = $wizardHoleSizeSelect.val()
      $holeSizeSelect
        .find(`option[value=${holeVal}]`)
        .attr("selected", true)

      // Trigger intput event - so that
      // the selected settings get stored fpr csg
      $studSizeSelect.trigger("input")
      $holeSizeSelect.trigger("input")

      disableWizard()
    }
    else {
      $wizardStepObjects[currentWizardStep]
        .fadeIn(wizardFadeTime)
    }

    // Update calibration preview on last step
    if (currentWizardStep === (wizardSteps.length - 1)) {
      const size = $wizardStudSizeSelect
        .find("option:selected")
        .html() +
        " " +
        $wizardHoleSizeSelect
          .find("option:selected")
          .html()
      return $calibrationSettings.html(size)
    }
  }

  const updateButtonCaptions = function () {
    if (currentWizardStep === (wizardSteps.length - 1)) {
      $nextButtonText.html("Finish")
    }
    else {
      $nextButtonText.html("Next step")
    }

    if (currentWizardStep === 0) {
      return $backButtonText.html("Cancel wizard")
    }
    else {
      return $backButtonText.html("Go back")
    }
  }

  // Bind button logic
  $nextButton.click(() => $wizardStepObjects[currentWizardStep]
    .fadeOut(wizardFadeTime, () => {
      currentWizardStep++
      applyCurrentWizardStep()
      return updateButtonCaptions()
    }))

  $backButton.click(() => $wizardStepObjects[currentWizardStep]
    .fadeOut(wizardFadeTime, () => {
      currentWizardStep--
      applyCurrentWizardStep()
      return updateButtonCaptions()
    }))

  // Fade out size select, start wizard on click
  return $startWizard.click(() => {
    currentWizardStep = 0
    updateButtonCaptions()
    $legoContent.fadeOut(wizardFadeTime)
    $stlContent.fadeOut(wizardFadeTime)
    return $sizeSelect.fadeOut(wizardFadeTime, () => {
      $wizardStepObjects[0].fadeIn(wizardFadeTime)
      return $wizardButtons.fadeIn(wizardFadeTime)
    })
  })
}

export function getModal (param) {
  if (param == null) {
    param = {}
  }
  const {testStrip, stl, lego, steps} = param
  if ($modal == null) {
    $modal = $("#downloadModal")
  }
  if ($legoContent == null) {
    $legoContent = $modal.find("#legoContent")
  }
  if ($stlContent == null) {
    $stlContent = $modal.find("#stlContent")
  }
  if ($testStripContent == null) {
    $testStripContent = $modal.find("#testStripContent")
  }

  if (lego) {
    $legoContent.show()
  }
  else {
    $legoContent.hide()
  }

  if (stl) {
    $stlContent.show()
  }
  else {
    $stlContent.hide()
  }

  if (testStrip) {
    $testStripContent.show()

    // Prefill select values
    $studSizeSelect = $modal.find("#studSizeSelect")
    $wizardStudSizeSelect = $modal.find("#wizardStudSizeSelect")
    addOptions($studSizeSelect, steps, 0, alphabeticalList)
    addOptions($wizardStudSizeSelect, steps, 0, alphabeticalList)

    $holeSizeSelect = $modal.find("#holeSizeSelect")
    $wizardHoleSizeSelect = $modal.find("#wizardHoleSizeSelect")
    addOptions($holeSizeSelect, steps, 0, numericalList)
    addOptions($wizardHoleSizeSelect, steps, 0, numericalList)
  }
  else {
    $testStripContent.hide()
  }

  if (!wizardLogicInitialized) {
    initializeWizard($modal)
  }

  // Reset wizard when closing the modal
  $modal.on("hidden.bs.modal", () => disableWizard())

  return $modal
}
