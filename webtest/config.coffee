exports.config =
  # See docs at https://github.com/brunch/brunch/blob/stable/docs/config.md.
  conventions:
    assets:  /^app\/assets\//
    ignored: /^(bower_components\/bootstrap-less(-themes)?|app\/styles\/overrides|(.*?\/)?[_]\w*)/
  modules:
    definition: false
    wrapper: false
  paths:
    public: '_public'
    watched: ['app', '../proto']
  files:
    javascripts:
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^(bower_components)/

    stylesheets:
      joinTo:
        'css/app.css': /^(app|bower_components)/
      order:
        before: [
          'app/styles/app.less'
        ]

    templates:
      joinTo:
        'js/dontUseMe' : /^app/ # dirty hack for Jade compiling.

  plugins:
    autoReload:
      port: 9485
    jade:
        pretty: yes # Adds pretty-indentation whitespaces to output (false by default)
    afterBrunch: [
        'rm -rf _public/proto',
        'cp -a ../proto _public/proto'
    ]

  # Enable or disable minifying of result js / css files.
  # minify: true
