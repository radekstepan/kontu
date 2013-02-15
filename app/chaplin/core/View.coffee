Chaplin = require 'chaplin'

Mediator = require 'chaplin/core/Mediator'

module.exports = class View extends Chaplin.View

    initialize: ->
        super

        # Garbage collect these.
        @views = []
        @timeouts = []

        @

    afterRender: ->
        super
        
        # Add our cid.
        $(@el).attr 'data-cid', @cid

    dispose: ->
        # Cleanup Views.
        ( v?.dispose() for v in @views )

        # Remove timeouts.
        ( clearTimeout(t) for t in @timeouts )

        # Stop listening to our music.
        Mediator.unsubscribe null, null, @
        
        super