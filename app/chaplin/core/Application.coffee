Chaplin = require 'chaplin'

require 'chaplin/core/AssertException' # assertions
require 'chaplin/core/Utils'           # utilities

Mediator = require 'chaplin/core/Mediator'
Layout = require 'chaplin/core/Layout'
Routes = require 'chaplin/core/Routes'

# The application object.
module.exports = class Application extends Chaplin.Application

    title: 'Kontu'

    initialize: ->
        super

        # Initialize core components
        @initDispatcher
            'controllerPath':   'chaplin/controllers/'
            'controllerSuffix': ''
        
        @initLayout()

        # Register all routes and start routing
        @initRouter Routes

        # Freeze the application instance to prevent further changes
        Object.freeze? @

    # Override standard layout initializer.
    initLayout: ->
        # Use an application-specific Layout class. Currently this adds
        # no features to the standard Chaplin Layout, it’s an empty placeholder.
        @layout = new Layout {@title}