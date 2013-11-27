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
    $scope.nodeQuery = ''
    $scope.packageQuery = ''

    fetchError = (name)->
      (data) ->
        console.log 'EE: cannot fetch '+name
        console.log data

    apiUrl = ()->
      if ($scope.ponyExpressHost + '').length > 0
        'http://'+$scope.ponyExpressHost+'/'+$scope.ponyExpressVersion
      else
        '/'+$scope.ponyExpressVersion

    $scope.updateUrl = ()->
      Restangular.setBaseUrl apiUrl()
      $scope.init()

    $scope.fetchNodes = ()->
      Restangular.all('nodes').getList().
        then (ns) ->
          console.log 'fetch nodes'
          $scope.nodes = ns
        , fetchError('nodes')

    $scope.fetchPackages = ()->
      Restangular.all('packages').getList().
        then (ns) ->
          console.log 'fetch packages'
          $scope.packages = ns
        , fetchError('packages')

    $scope.fetchNode = (id)->
      Restangular.one('node', id).get().
        then (n) ->
          console.log 'fetch node '+id
          n.id = id
          $scope.node[id] = n
        , fetchError('node')

    $scope.fetchPackage = (id)->
      Restangular.one('package', id).get().
        then (n) ->
          console.log 'fetch package '+id
          n.id = id
          $scope.package[id] = n
        , fetchError('packages')

    $scope.ensureNode = (id)->
      $scope.fetchNode(id) if not $scope.node[id]?

    $scope.init = ()->
      $scope.fetchNodes()
      $scope.fetchPackages()

    # initialize this module
    $? && $(document).ready ()->
      $scope.init()
  )