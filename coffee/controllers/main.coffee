root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, $cookies, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = $cookies.ponyExpressHost or undefined
    $scope.ponyExpressVersion = 'v1'
    $scope.nodes = []
    $scope.packages = []
    $scope.node = {}
    $scope.package = {}

    $scope.showConfig = false
    $scope.nodeVisible = {}
    $scope.nodeSelected = {}
    $scope.packageVisible = {}
    $scope.packageSelected = {}

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
          for p in ns
            for v in p.versions
              if not $scope.package[v.id]?
                $scope.package[v.id] = {}
                $scope.package[v.id].name = p.name
                $scope.package[v.id].version = v.version
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

    $scope.showNode = (id)->
      $scope.ensureNode(id)
      $scope.nodeVisible[id] = not $scope.nodeVisible[id]

    $scope.selectNode = (id)->
      console.log("node #{id} selected")
      $scope.ensureNode(id)
      $scope.nodeSelected[id] = not $scope.nodeSelected[id]
      # ... select packages from this node only ...
      $scope.showNode(id)

    $scope.showPackage = (p)->
      $scope.packageVisible[p.name] = not $scope.packageVisible[p.name]

    $scope.selectPackage = (p)->
      console.log("package #{p.name} selected")
      $scope.packageSelected[p.name] = not $scope.packageSelected[p.name]
      # ... query all versions of this package
      $scope.showPackage(p)

    $scope.loadData = ()->
      # update the cookie with a working url
      $cookies.ponyExpressHost = $scope.ponyExpressHost
      # set restangular to use the current url
      Restangular.setBaseUrl apiUrl()
      # fetch base data
      $scope.fetchNodes()
      $scope.fetchPackages()

    # initialize this module
    $? && $(document).ready ()->
      $scope.loadData()
  )