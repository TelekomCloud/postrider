root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = '127.0.0.1'
  )