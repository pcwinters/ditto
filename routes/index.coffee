project = require './project'

exports.project = project
exports.index = (req, res) ->
  res.render('index', { title: 'Express' });
