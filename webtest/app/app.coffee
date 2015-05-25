'use strict'

# Declare app level module which depends on filters, and services
App = angular.module('app', [
  'ngRoute'
  'app.controllers'
  'app.directives'
  'app.filters'
  'app.services'
  'partials'
])

App.config([
    '$routeProvider'
    ($routeProvider, config) ->
        $routeProvider
        .when('/chunkview', {templateUrl: '/partials/chunkview.html'})
        .otherwise({redirectTo: '/chunkview'})
])
