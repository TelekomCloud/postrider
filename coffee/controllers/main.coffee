root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = '127.0.0.1'
    $scope.nodes = []
    $scope.packages = []
    $scope.node = {}
    $scope.package = {}

    $scope.fetch_nodes = ()->
      Restangular.all('nodes').getList().
        then (ns) ->
          console.log 'fetch nodes'
          $scope.nodes = ns
        , (error) ->
          console.log 'EE: cannot fetch nodes'
          console.log error

    $scope.fetch_packages = ()->
      Restangular.all('packages').getList().
        then (ns) ->
          console.log 'fetch packages'
          $scope.packages = ns
        , (error) ->
          console.log 'EE: cannot fetch packages'
          console.log error

    $scope.fetch_node = (id)->
      Restangular.one('node', id).get().
        then (n) ->
          console.log 'fetch node '+id
          n['id'] = id
          $scope.node[id] = n
        , (error) ->
          console.log 'EE: cannot fetch node info for '+id
          console.log error

    $scope.fetch_package = (id)->
      Restangular.one('package', id).get().
        then (n) ->
          console.log 'fetch package '+id
          n['id'] = id
          $scope.package[id] = n
        , (error) ->
          console.log 'EE: cannot fetch package info for '+id
          console.log error

    $scope.ensure_node = (id)->
      $scope.fetch_node(id) if not $scope.node[id]?

    $scope.init = ()->
      $scope.fetch_nodes()
      $scope.fetch_packages()

    # initialize this module
    $? && $(document).ready ()->
      $scope.init()
  )