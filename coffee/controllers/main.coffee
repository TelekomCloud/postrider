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
    $scope.newMirrors = []
    $scope.editingMirror = {}

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

    fetchAllUnpaginated = (field, action, opts = {}) ->
      # fetch the field
      Restangular.all(field).getList( opts.query || {} ).then(
        (data) ->
          # if we have a result, process it
          console.log "fetched #{field} (no pagination)"
          action(data)
        , () ->
          # otherwise we have a fetch error
          fetchError("fetch #{field} (no pagination)")
        )

    fetchAllPaginated = (field, action, opts = {})->
      stop_when = opts.stop_when || isEmptyArray
      page = opts.page || 1
      limit = opts.limit || 50
      # construct a query for pagination
      query = _.merge(
        {page: page, limit: limit},
        ( opts.query || {} )
      )
      # fetch the field
      Restangular.all(field).getList(query).then(
        # success handling
        (data) ->
          console.log "fetched #{field} (page = #{page}, limit = #{limit})"
          action(data)
          # if we got a result and want to continue
          # then try fetching the next page
          if not stop_when(data)
            o = _.merge( (opts.query || {}),
              {'stop_when':stop_when, 'page':page + 1, 'limit': limit })
            fetchAllPaginated(field, action, o)
        # error handling
        , () ->
          # if we got an error on the first fetch, try again without pagination
          if page is 1
            return fetchAllUnpaginated(field, action, opts)
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
      filter_by = _.keys( _.pick( $scope.mirrorSelected, (val) -> val is true))
      $scope.allPackages = []

      # TODO: only limited to one mirror right now
      if filter_by.length > 0
        query = { 'outdated':true, 'mirror': filter_by[0] }
      else
        query = {}

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
                $scope.package[v.id].upstream = p.upstream
        , { 'query': query }

    $scope.fetchMirrors = (page = 1)->
      fetchAllPaginated 'mirrors',
        (data) ->
          # append the mirror to the list of mirrors
          $scope.mirrors.push.apply( $scope.mirrors, data )

    saveNewMirror = (mirror)->
      console.log "creating a new mirror..."
      # or if it's in the new elements, remove it first
      idx = $scope.newMirrors.indexOf(mirror)
      if idx >= 0
        $scope.newMirrors.splice( idx, 1 )
      else
        console.error "EE: can't remove new mirror: #{mirror}"
      # make the request to the server
      Restangular.one('mirrors').post('',mirror).
        then (n) ->
          $scope.mirrors.unshift( n )
        , fetchError('add mirror')

    saveExistingMirror = (mirror)->
      console.log "saving the existing mirror id: #{mirror.id}..."
      # remove the mirror from the list of editings
      $scope.editingMirror[mirror.id] = undefined
      # make the request to the server
      Restangular.one('mirrors', mirror.id).patch(mirror).
        then (n) ->
          idx = _.findIndex( $scope.mirrors, (i) -> i.id is mirror.id)
          if idx >= 0
            $scope.mirrors[idx] = n
          else
            console.error "EE: can't update mirror #{mirror.id}, "+
              "i can't find it in the list of mirrors"
        , fetchError('update mirror')

    $scope.saveMirror = (mirror)->
      if(mirror.id?)
        saveExistingMirror(mirror)
      else
        saveNewMirror(mirror)

    $scope.deleteMirror = (mirror)->
      idx = $scope.mirrors.indexOf(mirror)
      if( idx < 0)
        console.log("EE can't find mirror to delete")
        console.log(mirror)
      else
        Restangular.one('mirrors', mirror.id).remove().
          then (n) ->
            $scope.mirrors.splice(idx,1)
          , fetchError('delete mirror')

    $scope.newMirror = ()->
      # add a new mirror object to be edited
      $scope.newMirrors.push({})

    $scope.editMirror = (mirror)->
      # copy a cloned copy of all the entries to a separate object for editing
      $scope.editingMirror[mirror.id] = JSON.parse( JSON.stringify( mirror ) )

    $scope.cancelEditMirror = (mirror)->
      # if the mirror already exists
      if mirror.id?
        # remove it from the list of editings
        if $scope.editingMirror[mirror.id]?
          $scope.editingMirror[mirror.id] = undefined
        else
          console.error "Can't cancel editing for mirror (#{mirror.id})"
      # if the mirror is new and doesn't yet have an id
      else
        # remove it by index
        idx = $scope.newMirrors.indexOf(mirror)
        if idx >= 0
          $scope.newMirrors.splice(idx,1)
        else
          console.error "Can't cancel editing of new mirror #{mirror}."

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
      # update the list of packages with the selected repo
      $scope.fetchPackages()

    $scope.isPackageOutdated = (p)->
      # make sure we have upstream information
      return null if not p.upstream?
      # check if every version is on upstream:
      all = _.every( p.versions, {'version': p.upstream} )
      # check if any version is on upstream
      some = _.some( p.versions, {'version': p.upstream} )

      return 'some' if some and not all
      all is not true

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