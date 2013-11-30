root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, $cookies, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost = $cookies.ponyExpressHost or undefined
    $scope.ponyExpressVersion = 'v1'

    $scope.allNodes = []
    $scope.allPackages = []
    $scope.nodes = []
    $scope.packages = []
    $scope.node = {}
    $scope.package = {}
    $scope.packageByName = {}

    $scope.showConfig = false
    $scope.nodeVisible = {}
    $scope.nodeSelected = {}
    $scope.packageVisible = {}
    $scope.packageSelected = {}
    $scope.packageFetching = {}

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

    $scope.fetchNodes = (page = 1)->
      # construct a query for pagination
      # page == 0 means that we try to fetch without pagination (usually last attempt)
      query = if page is 0 then {} else {page: page, limit: 50}
      Restangular.all('nodes').getList(query).
        then (ns) ->
          console.log 'fetch nodes'
          $scope.allNodes = ns
          $scope.updateNodeSelection()
        , ()->
          # if we tried with pagination, try now without
          return $scope.fetchNodes(0) if page is 1
          # otherwise we have a fetch error
          fetchError("fetch nodes on page #{page}")

    $scope.fetchPackages = (page = 1)->
      # construct a query for pagination
      # page == 0 means that we try to fetch without pagination (usually last attempt)
      query = if page is 0 then {} else {page: page, limit: 50}
      # get packages
      Restangular.all('packages').getList(query).
        then (ns) ->
          console.log "fetch packages (page: #{page})"
          # append the new packages to the list of packages
          $scope.allPackages.push.apply( $scope.allPackages, ns )
          # update the selection, i.e. select nodes according to
          # new package information
          $scope.updatePackageSelection()
          # add all package info to the map
          for p in ns
            $scope.packageByName[p.name] = p
            for v in p.versions
              if not $scope.package[v.id]?
                $scope.package[v.id] = {}
                $scope.package[v.id].name = p.name
                $scope.package[v.id].version = v.version
          # get packages from the next page
          $scope.fetchPackages( page+1 )
        , ()->
          # if we tried with pagination, try now without
          return $scope.fetchPackages(0) if page is 1
          # otherwise we have a fetch error
          fetchError("fetch packages on page #{page}")

    $scope.fetchNode = (id)->
      Restangular.one('node', id).get().
        then (n) ->
          console.log 'fetch node '+id
          n.id = id
          $scope.node[id] = n
          $scope.updatePackageSelection()
        , fetchError('node')

    $scope.fetchPackage = (id, name)->
      $scope.packageFetching[name] += 1
      Restangular.one('package', id).get().
        then (n) ->
          console.log 'fetch package '+id
          n.id = id
          $scope.package[id] = n
          $scope.updateNodeSelection()
          $scope.packageFetching[name] -= 1
        , fetchError('packages')

    updateNodeSelectionFor = (packages)->
      # get all package ids for the list of package names
      pids = _(packages).
        # first we get all versions for this package name
        map( (p)-> $scope.packageByName[p].versions ).
        flatten().
        compact().
        # then get the package id for each package with version
        map( (v)-> v.id ).
        value()
      # get all nodes for the selected packages
      nodes = _(pids).
        map( (pid)->
          if $scope.package[pid]? and $scope.package[pid].nodes
            ( n.id for n in $scope.package[pid].nodes )
          else []
        ).
        flatten().
        uniq().
        value()
      # only keep nodes that were selected
      ns = _.reject $scope.allNodes, (n)->
        if _.indexOf(nodes, n.id) >= 0
          return false
        true
      # update the model of nodes subset
      $scope.nodes = ns

    $scope.updateNodeSelection = ()->
      # get all selected packages
      packages =
        ( k for k,isSelected of $scope.packageSelected when isSelected )
      if packages.length is 0
        $scope.nodes = $scope.allNodes
      else
        updateNodeSelectionFor(packages)

    updatePackageSelectionFor = (nodes)->
      # get all packages for these nodes
      packages = _(nodes).
        map( (n) ->
          if $scope.node[n]? and $scope.node[n].packages
            ( p.id for p in $scope.node[n].packages )
          else []
        ).
        flatten().
        uniq().
        value()
      # only keep packages that were selected
      ps = _.reject $scope.allPackages, (p)->
        for v in p.versions
          if _.indexOf(packages, v.id) >= 0
            return false
        true
      # update the model of package subsets
      $scope.packages = ps

    $scope.updatePackageSelection = ()->
      # get all selected nodes
      nodes = ( k for k,isSelected of $scope.nodeSelected when isSelected )
      if nodes.length is 0
        $scope.packages = $scope.allPackages
      else
        updatePackageSelectionFor(nodes)

    $scope.ensureNode = (id)->
      $scope.fetchNode(id) if not $scope.node[id]?

    $scope.ensurePackage = (p)->
      $scope.packageFetching[p.name] = 0 if not $scope.packageFetching[p.name]?
      for v in p.versions
        $scope.fetchPackage(v.id, p.name) if not $scope.package[v.id].nodes?

    $scope.showNode = (id)->
      $scope.ensureNode(id)
      $scope.nodeVisible[id] = not $scope.nodeVisible[id]

    $scope.selectNode = (id)->
      console.log("node #{id} selected")
      $scope.ensureNode(id)
      $scope.nodeSelected[id] = not $scope.nodeSelected[id]
      $scope.updatePackageSelection()
      $scope.showNode(id)

    $scope.showPackage = (p)->
      $scope.ensurePackage(p)
      $scope.packageVisible[p.name] = not $scope.packageVisible[p.name]

    $scope.selectPackage = (p)->
      console.log("package #{p.name} selected")
      $scope.ensurePackage(p)
      $scope.packageSelected[p.name] = not $scope.packageSelected[p.name]
      $scope.updateNodeSelection()
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