exports.config =
    files:
        javascripts:
            joinTo:
                'js/app.js': /^app\/(chaplin|tools)/
                'js/vendor.js': /^vendor\/js/
            order:
                before: [
                    'vendor/js/jquery-1.7.2.js',
                    'vendor/js/underscore-1.3.3.js',
                    'vendor/js/backbone-0.9.9.js',
                ]

        stylesheets:
            joinTo:
                'css/app.css': /^app\/styles/
                'css/vendor.css': /^vendor\/css/
            order:
                before: [
                    'vendor/css/foundation3.css'
                ]
                after: [
                    'app/styles/app.styl'
                ]

        templates:
            joinTo: 'js/app.js'

    server:
        path: 'src/service.coffee'
        port: 5000
        run: yes