exports.paths = {
  watched: ['app', 'test', 'vendor', '../proto', 'server.build_time']
}

exports.files = {
  javascripts: {
    joinTo: {
      'app.js': /^app/,
      'vendor.js': /^node_modules/
    }
  },
  stylesheets: {joinTo: 'app.css'},
  templates: {joinTo: 'app.js'},
};

exports.server = {
  hostname: '0.0.0.0'
}

exports.plugins = {
  copycat: {
    "proto": ["../proto"]
  }
}
