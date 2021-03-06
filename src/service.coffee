flatiron = require 'flatiron'
union    = require 'union'
director = require 'director'
connect  = require 'connect'
send     = require 'send'
mongodb  = require 'mongodb'
Q        = require 'q'

CONFIG = {}
DB     = null

exports.startServer = (port=5000, dir='public', done) ->
    # Setup.
    CONFIG.port = process.env.PORT or port
    CONFIG.env = process.env.NODE_ENV or 'production'

    # If we are in test mode and we are already running, just return.
    if CONFIG.env is 'test' and DB then return done()

    app = flatiron.app

    app.use flatiron.plugins.http,
        'before': [
            # Have a nice favicon.
            connect.favicon()
            # Static file serving.
            connect.static "./#{dir}"
        ]
        'onError': (err, req, res) ->
            if err.status is 404
                # Silently serve the root of the client app.
                send(req, 'index.html')
                    .root("./#{dir}")
                    .on('error', union.errorHandler)
                    .pipe(res)
            else
                # Go Union!
                union.errorHandler err, req, res

    # Use MongoDB.
    app.use
        name: 'mongodb'
        attach: (options) ->
            app.db = (done) ->
                # Get one collection back.
                collection = (conn, name) ->
                    def = Q.defer()
                    conn.collection CONFIG.env + ':' + name, (err, coll) ->
                        if err then return def.reject err
                        else def.resolve [ name, coll ]
                    def.promise

                unless DB?
                    # Connect to the database.
                    mongodb.Db.connect 'mongodb://localhost:27017/kontu', (err, conn) ->
                        throw err if err
                        Q.all([ collection(conn, 'ledger'), collection(conn, 'users') ]).done( (collections) ->
                            temp = {}
                            ( temp[name] = coll for [ name, coll ] in collections )
                            done DB = temp
                        , (err) ->
                            throw err
                        )
                else
                    done DB

    # Require & set our app.
    Kontu = require './kontu'
    kontu = new Kontu app.db

    # All the routes an their mapping.
    routes =
        '/api':
            '/users':        kontu.user
            '/invite':       kontu.invite
            '/accounts':     kontu.account
            '/transactions': kontu.transaction
            # Remove the following testing routes.
            '/clean':
                get: ->
                    res = @res

                    clean = (collection) ->
                        def = Q.defer()
                        collection.remove {}, (err, removed) ->
                            if err then return def.reject err
                            else def.resolve()
                        def.promise

                    app.db (collections) ->
                        Q.all([ clean(collections.users), clean(collections.ledger) ]).done( ->
                            res.writeHead 200
                            res.end()
                        , ->
                            res.writeHead 500
                            res.end()
                        )

    # Cleanup the collections in a database?
    if CONFIG.env isnt 'test' then delete routes['/api']['/clean']

    # Instantiate the Director router.
    app.router = new director.http.Router routes

    # Start Flatiron on port.
    app.start CONFIG.port, (err) ->
        throw err if err
        if done and typeof(done) is 'function' then done app