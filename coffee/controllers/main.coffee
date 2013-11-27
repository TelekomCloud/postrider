root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = undefined
    $scope.ponyExpressVersion = 'v1'
    $scope.nodes = []
    $scope.packages = []
    $scope.node = {}
    $scope.package = {}
    $scope.showConfig = false

    fetch_error = (name)->
      (data) ->
        console.log 'EE: cannot fetch '+name
        console.log data

    api_url = ()->
      if ($scope.ponyExpressHost + '').length > 0
        'http://'+$scope.ponyExpressHost+'/'+$scope.ponyExpressVersion
      else
        '/'+$scope.ponyExpressVersion

    $scope.update_url = ()->
      Restangular.setBaseUrl api_url()
      $scope.init()

    $scope.fetch_nodes = ()->
      Restangular.all('nodes').getList().
        then (ns) ->
          console.log 'fetch nodes'
          $scope.nodes = ns
        , fetch_error('nodes')

    $scope.fetch_packages = ()->
      Restangular.all('packages').getList().
        then (ns) ->
          console.log 'fetch packages'
          $scope.packages = ns
        , fetch_error('packages')

    $scope.fetch_node = (id)->
      Restangular.one('node', id).get().
        then (n) ->
          console.log 'fetch node '+id
          n['id'] = id
          $scope.node[id] = n
        , fetch_error('node')

    $scope.fetch_package = (id)->
      Restangular.one('package', id).get().
        then (n) ->
          console.log 'fetch package '+id
          n['id'] = id
          $scope.package[id] = n
        , fetch_error('packages')

    $scope.ensure_node = (id)->
      $scope.fetch_node(id) if not $scope.node[id]?

    $scope.init = ()->
      $scope.fetch_nodes()
      $scope.fetch_packages()

    # initialize this module
    $? && $(document).ready ()->
      $scope.init()
  )