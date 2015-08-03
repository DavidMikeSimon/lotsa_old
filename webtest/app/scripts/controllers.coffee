### Controllers ###

angular.module('app.controllers', [])

.controller 'AppCtrl', ->
  null

.controller 'ChunkViewCtrl', ($scope, MyData) ->
   $scope.MyData = MyData
