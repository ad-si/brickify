!function () {

	function iconify (value) {
		if (value === true)
			return '✔'
		if (value === false)
			return '✘'

		return value
	}

	function executeOnlyOnNumbers (value1, value2, callback) {
		if (value1 == null) {
			if (value2 == null)
				return null
			else
				return value2
		}
		else {
			if (value2 == null)
				return value1
			else
				return callback(value1, value2)
		}
	}

	function getMax (value1, value2) {
		return executeOnlyOnNumbers(value1, value2, Math.max)
	}

	function getMin (value1, value2) {
		return executeOnlyOnNumbers(value1, value2, Math.min)
	}

	function getStatistics (data) {

		return data
			.models
			.reduce(function (previous, current, index, array) {

				Object.keys(previous)
					.forEach(function (key) {

						var value = {
							min: getMin(previous[key].min, current[key]),
							max: getMax(previous[key].max, current[key]),
							sum: (Number(previous[key].sum) ||
							0) + (Number(current[key]) || 0)
						}

						if (index === array.length - 1) {
							value.average = value.sum / array.length
							// TODO: Average per polygon
							//value.averagePerPolygon = value.sum /
						}

						current[key] = value
					})

				return current
			},
			Object
				.keys(data.models[0])
				.reduce(function (previous, current) {
					previous[current] = {}
					return previous
				}, {})
		)
	}

	function renderStatistics (statsObject) {

		var tableBody = document.querySelector('#generalStatistics tbody')

		tableBody.innerHTML = ''

		Object.keys(statsObject)
			.forEach(function (metric) {
				var row,
					metricCell, strongElement

				row = document.createElement('tr')
				tableBody.appendChild(row)

				metricCell = document.createElement('td')
				strongElement = document.createElement('strong')
				strongElement.textContent = metric
				metricCell.appendChild(strongElement)
				row.appendChild(metricCell)

				Object.keys(statsObject[metric])
					.forEach(function (statKey) {
						var cell = document.createElement('td')
						cell.textContent = statsObject[metric][statKey]
						cell.title = statKey
						row.appendChild(cell)
					})
			})
	}

	function renderAbsoluteTable (data) {

		var tableBody

		if (!data.models)
			throw new Error('Models array is empty!')

		tableBody = document.querySelector('#absoluteValues tbody')

		tableBody.innerHTML = ''

		data.models.forEach(function (model) {

			var row,
				key

			row = document.createElement('tr')

			tableBody.appendChild(row)

			Object.keys(model)
				.forEach(function (key) {
					var cell = document.createElement('td')
					cell.textContent = iconify(model[key])
					cell.title = key
					row.appendChild(cell)
				})
		})
	}

	function loadData () {

		var request = new XMLHttpRequest()

		request.open('GET', "./data.jsonl", true)
		request.onreadystatechange = function () {

			var jsonString,
				data

			if (request.readyState != 4)
				return

			if (request.status != 200)
				throw new Error(request.status)

			jsonString = '{"models": [' +
			             request.responseText.replace(/}\n\{/g, '},{') +
			             ']}'

			data = JSON.parse(jsonString)

			renderAbsoluteTable(data)
			renderStatistics(getStatistics(data))
		}

		request.send()
	}


	document
		.querySelector('#updateButton')
		.addEventListener('click', loadData)

}()
