express = require('express')
routes = require('./routes')
http = require('http')
path = require('path')
_ = require('underscore')
rest = require('restler')

liveDbMongo = require 'livedb-mongo'
redis = require('redis').createClient()
racerBrowserChannel = require 'racer-browserchannel'
racer = require 'racer'

redis.select 13
liveDbClient = liveDbMongo('localhost/demo?auto_reconnect', safe: true)

console.log liveDbClient.getSnapshot
for operation in ['getSnapshot', 'getBulkSnapshots', 'queryDoc', 'writeSnapshot']
	_op = liveDbClient[operation]
	do (_op, operation) ->
		liveDbClient[operation] = () ->
			console.log "#{operation} : #{arguments[0]} : #{arguments[1]}"
			_op.apply(this, arguments)


_getSnapshot = liveDbClient.getSnapshot
liveDbClient.getSnapshot = (cname, docname, callback) ->
	myCallback = (err, snapshotResults) ->
		console.log "results #{[snapshotResults.type, snapshotResults.v, snapshotResults.docName, snapshotResults.data.title]}"
		
		options = {
			username: 'pwinters@rallydev.com'
			password: 'Itsme123'
			parser: rest.parsers.json
		}
		
		rest.get('https://rally1.rallydev.com/slm/webservice/v2.0/hierarchicalrequirement?fetch=true', options).on 'complete', (result, response) ->
			console.log "rest #{typeof result}"
			results = result.QueryResult.Results
			_.each results, (i) ->
				i.title = i.Name
				i.number = i.FormattedID
				i.type = 'US'
				console.log "#{i.number} : #{i.title}"
			
			snapshotResults.data.stories = results
			callback err, snapshotResults
		
		
	_getSnapshot.apply this, [cname, docname, myCallback]


store = racer.createStore
  db: liveDbClient
  redis: redis

app = express()

app.configure () ->
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(racerBrowserChannel store)
  app.use(store.modelMiddleware())
  app.use(express.static(path.join(__dirname, 'public')));
  app.use(app.router);
  
app.configure 'development', () ->
  app.use(express.errorHandler())

app.get '/', routes.index
app.get '/project/:projectId', routes.project


app.get '/model', (req, res) ->
	model = store.createModel()
	model.bundle (err, bundle) ->
		res.send(JSON.stringify(bundle))
#	model.subscribe 'entries', (err, entries) ->
#		if err
#			res.status(500)
#			res.send(err)
#		else
#			model.bundle (err, bundle) ->
#				res.send(JSON.stringify(bundle))
			
	
store.bundle __dirname+"/client.js", (err, js) ->
	app.get '/script.js', (req, res) ->
		res.type('js');
		res.send(js);

http.createServer(app).listen app.get('port'), () ->
  console.log("Express server listening on port " + app.get('port'))

