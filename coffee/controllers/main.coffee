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
    $scope.repos = []
    $scope.node = {}
    $scope.package = {}
    $scope.packageByName = {}

    $scope.show = {}
    $scope.nodeVisible = {}
    $scope.nodeSelected = {}
    $scope.packageVisible = {}
    $scope.packageSelected = {}
    $scope.packageFetching = {}
    $scope.repoSelected = {}
    $scope.repoSelectedLabel = null
    $scope.selectedReposIndicator = '...'
    $scope.newRepos = []
    $scope.editingRepo = {}

    $scope.nodeQuery = ''
    $scope.packageQuery = ''

    # smart toggle function: toggle a field in a group
    # if no field is active in the group, just activate this field
    # if this field is already active, deactivate it
    # if a field is choosen while another is active, the new one
    #   will become active
    # example: toggleShow('nav', 'config'), toggleShow('nav', 'repos'),
    # toggleShow('nav', 'repos')
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
            o = {
              'stop_when':stop_when,
              'page':page + 1,
              'limit': limit,
              'query': (opts.query || {})
            }
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
      # empty out the current nodes
      $scope.allNodes = []
      # fetch the list of nodes
      fetchAllPaginated 'nodes',
        (data) ->
          # append the new nodes to the list of nodes
          $scope.allNodes.push.apply( $scope.allNodes, data )
          # update the selectoin, i.e. select packages according to
          # new node information
          $scope.updateNodeSelection()

    $scope.fetchPackages = (page = 1)->
      $scope.allPackages = []
      $scope.allPackagesMap = {}

      # If a repo was selected, filter by it
      if $scope.repoSelectedIds().length isnt 0
        query = { 'outdated':true, 'repo': $scope.repoSelectedIds().join(",") }
      else if $scope.repoSelectedLabel?
        query = { 'outdated':true, 'repolabel': $scope.repoSelectedLabel }
      else
        query = {}

      fetchAllPaginated 'packages',
        (data) ->
          # append the new packages to the list of packages
          for p in data
            if not $scope.allPackagesMap[p.name]?
              $scope.addOutdatedInfo(p)
              $scope.allPackagesMap[p.name] = true
              $scope.allPackages.push( p )
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

    $scope.fetchRepos = (page = 1)->
      # empty out the list of repositories
      $scope.repos = []
      # get all repositories
      fetchAllPaginated 'repositories',
        (data) ->
          # append any new repo to the list of repos
          $scope.repos.push.apply( $scope.repos, data )

    saveNewRepo = (repo)->
      console.log "creating a new repo..."
      # or if it's in the new elements, remove it first
      idx = $scope.newRepos.indexOf(repo)
      if idx >= 0
        $scope.newRepos.splice( idx, 1 )
      else
        console.error "EE: can't remove new repo: #{repo}"
      # make the request to the server
      Restangular.one('repositories').post('',repo).
        then (n) ->
          $scope.repos.unshift( n )
        , fetchError('add repo')

    saveExistingRepo = (repo)->
      console.log "saving the existing repo id: #{repo.id}..."
      # remove the repo from the list of editings
      $scope.editingRepo[repo.id] = undefined
      # make the request to the server
      Restangular.one('repositories', repo.id).patch(repo).
        then (n) ->
          idx = _.findIndex( $scope.repos, (i) -> i.id is repo.id)
          if idx >= 0
            $scope.repos[idx] = n
          else
            console.error "EE: can't update repo #{repo.id}, "+
              "i can't find it in the list of repos"
        , fetchError('update repo')

    $scope.saveRepo = (repo)->
      if(repo.id?)
        saveExistingRepo(repo)
      else
        saveNewRepo(repo)

    $scope.deleteRepo = (repo)->
      idx = $scope.repos.indexOf(repo)
      if( idx < 0)
        console.log("EE can't find repo to delete")
        console.log(repo)
      else
        Restangular.one('repositories', repo.id).remove().
          then (n) ->
            $scope.repos.splice(idx,1)
          , fetchError('delete repo')

    $scope.newRepo = ()->
      # add a new repo object to be edited
      $scope.newRepos.push({})

    $scope.editRepo = (repo)->
      # copy a cloned copy of all the entries to a separate object for editing
      $scope.editingRepo[repo.id] = JSON.parse( JSON.stringify( repo ) )

    $scope.cancelEditRepo = (repo)->
      # if the repo already exists
      if repo.id?
        # remove it from the list of editings
        if $scope.editingRepo[repo.id]?
          $scope.editingRepo[repo.id] = undefined
        else
          console.error "Can't cancel editing for repo (#{repo.id})"
      # if the repo is new and doesn't yet have an id
      else
        # remove it by index
        idx = $scope.newRepos.indexOf(repo)
        if idx >= 0
          $scope.newRepos.splice(idx,1)
        else
          console.error "Can't cancel editing of new repo #{repo}."

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

    $scope.repoLabels = ()->
      _.uniq( $scope.repos.map((x) -> x.label) )

    $scope.repoSelectedIds = ()->
      _.keys( $scope.repoSelected )

    $scope.updateSelectedReposIndicator = ()->
      if $scope.repoSelectedLabel?
        $scope.selectedReposIndicator = $scope.repoSelectedLabel
      else if $scope.repoSelectedIds().length isnt 0
        repoNames = _.values( $scope.repoSelected ).map((x) -> x.name )
        $scope.selectedReposIndicator = repoNames.join(', ')
      else
        $scope.selectedReposIndicator = '...'

    $scope.selectRepo = (m)->
      if m? and m.id?
        if $scope.repoSelected[m.id]?
          console.log "repo deselect #{m.name} (#{m.id})"
          delete $scope.repoSelected[m.id]
        else
          console.log("repo select #{m.name} (#{m.id})")
          $scope.repoSelected[m.id] = m
        # deselect repo selection by Label
        $scope.repoSelectedLabel = null
      else
        console.log("repo deselect all")
        $scope.repoSelected = {}
        $scope.repoSelectedLabel = null
      # update the list of packages with the selected repo
      $scope.updateSelectedReposIndicator()
      $scope.fetchPackages()

    $scope.selectRepoLabel = (label)->
      if label? and label isnt ''
        console.log("selecting repo label: #{label}")
        $scope.repoSelectedLabel = label
        # deselect repo selection by ID
        $scope.repoSelected = {}
      # update the list of packages with the selected repo
      $scope.updateSelectedReposIndicator()
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

    $scope.addOutdatedInfo = (p)->
      p.isOutdated = $scope.isPackageOutdated(p)
      if p.isOutdated is 'some' or p.isOutdated is true
        oldest = p.versions.map((x)->x['version']).sort()[0]
        p.outdated_info = "latest: " + p.upstream

    $scope.loadData = ()->
      # update the cookie with a working url
      $cookies.ponyExpressHost = $scope.ponyExpressHost
      # set restangular to use the current url
      Restangular.setBaseUrl apiUrl()
      # fetch base data
      $scope.fetchNodes()
      $scope.fetchPackages()
      $scope.fetchRepos()

    # initialize this module
    $? && $(document).ready ()->
      $scope.loadData()
  )