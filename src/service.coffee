flatiron = require 'flatiron'
mongodb  = require 'mongodb'
Q        = require 'q'

CONFIG = {}
DB     = null

exports.start = (port, done) ->
    # Setup.
    CONFIG.port = process.env.PORT or port
    CONFIG.env = process.env.NODE_ENV or 'production'

    # If we are in test mode and we are already running, just return.
    if CONFIG.env is 'test' and DB then return done()

    app = flatiron.app

    app.use flatiron.plugins.http

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

    app.router.path '/api/users',        kontu.user
    app.router.path '/api/invite',       kontu.invite
    app.router.path '/api/accounts',     kontu.account
    app.router.path '/api/transactions', kontu.transaction

    # Cleanup the collections in a database.
    if CONFIG.env is 'test'
        clean = (collection) ->
            def = Q.defer()
            collection.remove {}, (err, removed) ->
                if err then return def.reject err
                else def.resolve()
            def.promise

        app.router.path '/api/clean', ->
            @get ->
                res = @res
                app.db (collections) ->
                    Q.all([ clean(collections.users), clean(collections.ledger) ]).done( ->
                        res.writeHead 200
                        res.end()
                    , ->
                        res.writeHead 500
                        res.end()
                    )

    # Start Flatiron on port.
    app.start CONFIG.port, (err) ->
        throw err if err
        done app