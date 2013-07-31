
module.exports = (req, res, next) ->
	projectId = req.params.projectId;
	model = req.getModel()
	project = model.at("projects.#{projectId}")
	project.subscribe (err) ->
		if err? then return next err
		if not project.get('title')? then project.set 'title', "Project#{projectId}"
		stories = project.at('stories')
		if not stories.get()?
			console.log 'Setting stories to empty array'
			stories.set([{number:'USTest', title:'this is a test item'}])
		project.bundle (err, bundle) ->
			console.log "sending bundle #{err?}"
			if err? then return next err
			res.send(JSON.stringify(bundle))
    