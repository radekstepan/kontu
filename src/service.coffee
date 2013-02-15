flatiron = require 'flatiron'
mongodb  = require 'mongodb'
Q        = require 'q'

CONFIG = {}
DB     = null

exports.start = (port, done) ->
    # Setup.
    CONFIG.port = process.env.PORT or port
    CONFIG.env = process.env.NODE_ENV or 'production'

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
                        if err then def.reject err
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
    kontu = require './kontu'
    kontu.app app

    app.router.path '/api/users',        kontu.users
    app.router.path '/api/accounts',     kontu.accounts
    app.router.path '/api/transactions', kontu.transactions

    # Start Flatiron on port.
    app.start CONFIG.port, (err) ->
        throw err if err
        done app