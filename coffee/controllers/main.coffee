root = exports ? this

angular.module('postriderApp')
  .controller('MainCtrl', ($scope, $cookies, Restangular) ->
    root.scope = $scope

    $scope.ponyExpressHost =
      $cookies.ponyExpressHost or ( window.location.host + "/api" )
    $scope.ponyExpressVersion = 'v1'

    $scope.allNodes = []
    $scope.allPackages = []
    $scope.nodes = []
    $scope.packages = []
    $scope.mirrors = []
    $scope.node = {}
    $scope.package = {}
    $scope.packageByName = {}

    $scope.show = {}
    $scope.nodeVisible = {}
    $scope.nodeSelected = {}
    $scope.packageVisible = {}
    $scope.packageSelected = {}
    $scope.packageFetching = {}
    $scope.mirrorSelected = {}

    $scope.nodeQuery = ''
    $scope.packageQuery = ''

    # smart toggle function: toggle a field in a group
    # if no field is active in the group, just activate this field
    # if this field is already active, deactivate it
    # if a field is choosen while another is active, the new one
    #   will become active
    # example: toggleShow('nav', 'config'), toggleShow('nav', 'mirrors'),
    # toggleShow('nav', 'mirrors')
    $scope.toggleShow = (group, field)->
      if $scope.show[group] == field
        $scope.show[group] = undefined
      else
        $scope.show[group] = field

    fetchError = (name)->
      (data) ->
        console.log 'EE: cannot fetch '+name
        console.log data

    apiUrl = ()->
      if ($scope.ponyExpressHost + '').length > 0
        'http://'+$scope.ponyExpressHost+'/'+$scope.ponyExpressVersion
      else
        '/'+$scope.ponyExpressVersion

    isEmptyArray = (x) ->
      x instanceof Array and x.length == 0

    fetchAllUnpaginated = (field, action) ->
      # fetch the field
      Restangular.all(field).getList().then(
        (data) ->
          # if we have a result, process it
          console.log "fetched #{field} (no pagination)"
          action(data)
        , () ->
          # otherwise we have a fetch error
          fetchError("fetch #{field} (no pagination)")
        )

    fetchAllPaginated = (
      field, action, stop_when = isEmptyArray,
      page = 1, limit = 50
      )->
      # construct a query for pagination
      query = {page: page, limit: limit}
      # fetch the field
      Restangular.all(field).getList(query).then(
        # success handling
        (data) ->
          console.log "fetched #{field} (page = #{page}, limit = #{limit})"
          action(data)
          # if we got a result and want to continue
          # then try fetching the next page
          if not stop_when(data)
            fetchAllPaginated(field, action, stop_when, page + 1, limit)
        # error handling
        , () ->
          # if we got an error on the first fetch, try again without pagination
          if page is 1
            return fetchAllUnpaginated(field, action)
          # otherwise we have a fetch error
          fetchError("fetch #{field} on page #{page}, limit #{limit}")
        )

    $scope.fetchNodes = (page = 1)->
      fetchAllPaginated 'nodes',
        (data) ->
          # append the new nodes to the list of nodes
          $scope.allNodes.push.apply( $scope.allNodes, data )
          # update the selectoin, i.e. select packages according to
          # new node information
          $scope.updateNodeSelection()

    $scope.fetchPackages = (page = 1)->
      fetchAllPaginated 'packages',
        (data) ->
          # append the new packages to the list of packages
          $scope.allPackages.push.apply( $scope.allPackages, data )
          # update the selection, i.e. select nodes according to
          # new package information
          $scope.updatePackageSelection()
          # add all package info to the map
          for p in data
            $scope.packageByName[p.name] = p
            for v in p.versions
              if not $scope.package[v.id]?
                $scope.package[v.id] = {}
                $scope.package[v.id].name = p.name
                $scope.package[v.id].version = v.version

    $scope.fetchMirrors = (page = 1)->
      fetchAllPaginated 'mirrors',
        (data) ->
          # append the mirror to the list of mirrors
          $scope.mirrors.push.apply( $scope.mirrors, data )

    $scope.addMirror = (mirror)->
      Restangular.one('mirrors').post('',mirror).
        then (n) ->
          $scope.mirrors.push( n )
        , fetchError('add mirror')

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

    $scope.selectMirror = (m)->
      console.log("mirror #{m.name} (#{m.id}) selected")
      $scope.mirrorSelected[m.id] = not $scope.mirrorSelected[m.id]

    $scope.loadData = ()->
      # update the cookie with a working url
      $cookies.ponyExpressHost = $scope.ponyExpressHost
      # set restangular to use the current url
      Restangular.setBaseUrl apiUrl()
      # fetch base data
      $scope.fetchNodes()
      $scope.fetchPackages()
      $scope.fetchMirrors()

    # initialize this module
    $? && $(document).ready ()->
      $scope.loadData()
  )