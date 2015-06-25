path = require 'path'

module.exports.getLandingpage = (request, response) ->
	response.render(
		path.join('landingpage', 'landingpage')
		page: 'landing'
		models: [
			{
				hash: '708d0b0b44f491523de951afa44b3e06'
				img: 'sample_ballista.png'
			},
			{
				hash: 'cd8a7a94eac03bf07f32048269e5cc1f'
				img: 'sample_CitrusJuicer.png'
			},
			{
				hash: '1c2395a3145ad77aee7479020b461ddf'
				img: 'sample_goggles.png'
			},
			{
				hash: '1b2512f0804dfd68b2783108d840ab6f'
				img: 'sample_printableWrench.png'
			}
		]
	)

module.exports.getContribute = (request, response) ->
	response.render(
		path.join('landingpage', 'contribute')
		pageTitle: 'Contribute'
	)

module.exports.getTeam = (request, response) ->
	response.render(
		path.join('landingpage', 'team')
		pageTitle: 'Team'
	)

module.exports.getImprint = (request, response) ->
	response.render(
		path.join('landingpage', 'imprint')
		pageTitle: 'Imprint'
	)

module.exports.getEducators = (request, response) ->
	response.render(
		path.join('landingpage', 'educators')
		{
			page: 'landing',
			pageTitle: 'Educators'
		}
	)
