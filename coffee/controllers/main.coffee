root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = '127.0.0.1'
    $scope.nodes = []
    $scope.node = {}

    $scope.fetch = ()->
      Restangular.all('nodes').getList().
        then (ns) ->
          console.log 'fetch nodes: '
          console.log ns
          $scope.nodes = ns
        , (error) ->
          console.log 'EE: cannot fetch data'
          console.log error

    $scope.fetch_node = (id)->
      Restangular.one('node', id).get().
        then (n) ->
          console.log 'fetch node '+id+': '
          console.log n
          n['id'] = id
          $scope.node[id] = n
        , (error) ->
          console.log 'EE: cannot fetch node info for '+id
          console.log error

    $scope.ensure_node = (id)->
      $scope.fetch_node(id) if not $scope.node[id]?

    $scope.init = ()->
      $scope.fetch()

    # initialize this module
    $? && $(document).ready ()->
      $scope.init()
  )