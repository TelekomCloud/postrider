'use strict'

describe 'Controller: MainCtrl', ()->

  # load the required module
  beforeEach(angular.mock.module('restangular'))

  # load the controller's module
  beforeEach(module('postriderApp'))

  # Initialize the controller and a mock scope
  beforeEach( inject( ($injector, $controller, $rootScope) ->
    scope = $rootScope.$new()
    @Restangular = $injector.get('Restangular')
    @httpBackend = $injector.get('$httpBackend')

    # reliably determine object types
    # http://stackoverflow.com/questions/7390426/better-way-to-get-type-of-a-javascript-variable
    @typeOf = (obj) ->
      ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

    MainCtrl = $controller('MainCtrl', {
      $scope: scope,
      Restangular: @Restangular
    })
  ))

  afterEach () ->
    @httpBackend.verifyNoOutstandingExpectation()
    @httpBackend.verifyNoOutstandingRequest()


  # Some Mockup data:
  #------------------

  allNodes1 = nodes = [
    { 'id': 'my1.full.fqdn' },
    { 'id': 'my2.full.fqdn' }
  ]

  allPackages1 = [
    { 'name': 'xx', 'versions': [
        {'version':'1.0','id':'xx10'}
      ]
    },
    { 'name': 'yy', 'versions': [
        {'version':'1.1','id':'yy11'},
        {'version':'1.2','id':'yy12'}
      ]
    }
  ]

  allPackages2 = [
    { 'name': 'xx', 'versions': [
        {'version':'1.0','id':'xx10'}
      ], 'upstream': '1.0'
    },
    { 'name': 'yy', 'versions': [
        {'version':'1.1','id':'yy11'},
        {'version':'1.2','id':'yy12'}
      ], 'upstream': '2.0'
    }
  ]

  allRepos1 = [
    {
      'id': '44e5f422-62db-42dc-b1ce-37ca3393710f',
      'name': 'Magus Repository',
      'label': 'live',
      'url': 'http://archive.canonical.com/ubuntu/dists/precise/partner/binary-amd64/Packages.gz',
      'provider': 'apt'
    }
  ]

  allRepos2 = allRepos1.concat [
    {
      'id': '44e5f422-62db-42dc-b1ce-37ca3393710e',
      'name': 'Minas Thorun',
      'label': 'ref',
      'url': 'http://archive2.canonical.com/ubuntu/dists/precise/partner/binary-amd64/Packages.gz',
      'provider': 'apt'
    }
  ]

  package1 = {
      'name': 'accountsservice',
      'uri': 'http://us.archive.ubuntu.com/ubuntu/pool/main/a/accountsservice/accountsservice_0.6.15-2ubuntu9_amd64.deb',
      'summary': 'query and manipulate user account information',
      'version': '0.6.15-2ubuntu9',
      'architecture': 'amd64',
      'provider': 'apt',
      'archive': 'precise',
      'nodes': [
        'my1.full.fqdn'
      ]
    }

  package2 = {
      'name': 'otherservice',
      'uri': 'http://us.archive.ubuntu.com/ubuntu/pool/main/o/otherservice/otherservice_0.6.15-2ubuntu9_amd64.deb',
      'summary': 'some other service',
      'version': '0.2-2ubuntu9',
      'architecture': 'amd64',
      'provider': 'apt',
      'archive': 'precise',
      'nodes': [
        'my2.full.fqdn'
      ]
    }


  ## Helpers:
  ##---------

  build_request = (site, params = [])->
    # remove all undefined
    p = params.filter (x) -> x?
    q = ( p.map (x) -> x.join('=') ).sort().join('&')
    if q.length == 0
      site
    else
      "#{site}?#{q}"

  paginateResponse = (httpBackend, baseUrl, response, action, opts = {})->
    limit = opts.limit || 50
    query = [['limit', limit]].concat opts.query
    # 1. working pagination
    #    it will request page 1, get it,
    #    and request page 2 and finish
    url = build_request baseUrl, query.concat [['page', 1]]
    httpBackend.whenGET(url).respond(response)
    httpBackend.expectGET(url)
    url = build_request baseUrl, query.concat [['page', 2]]
    httpBackend.whenGET(url).respond(410,'Gone')
    httpBackend.expectGET(url)
    # take the action and flush the backend
    action()
    httpBackend.flush()

  dontPaginateResponse = (httpBackend, baseUrl, response, action, opts = {})->
    limit = opts.limit || 50
    query = [['limit', limit]].concat opts.query
    # 2. no pagination
    #    it will request page 1, won't get it
    #    and try without pagination
    url = build_request baseUrl, query.concat [['page', 1]]
    httpBackend.whenGET(url).respond(410,'Gone')
    httpBackend.expectGET(url)
    url = build_request baseUrl, opts.query || []
    httpBackend.whenGET(url).respond(response)
    httpBackend.expectGET(url)
    # take the action and flush the backend
    action()
    httpBackend.flush()

  callResponse = ($httpBackend, baseUrl, requestType, responseCode, response, action)->
    $httpBackend["when#{requestType}"](baseUrl).respond(responseCode,response)
    $httpBackend["expect#{requestType}"](baseUrl)
    # take the action
    action()
    $httpBackend.flush()


  # The tests:
  #-----------

  ## Configuration

  it 'should have the default host pointing to <HOST>/api', () ->
    expect(scope.ponyExpressHost).toBe( window.location.host + "/api" )

  ## Querying Nodes and Package

  it 'should paginate /nodes if it supports pagination', ()->
    paginateResponse @httpBackend, '/v1/nodes', allNodes1, () -> scope.fetchNodes()
    expect(scope.nodes.length).toBe(allNodes1.length)

  it 'should not paginate /nodes if it doesnt supports pagination', ()->
    dontPaginateResponse @httpBackend, '/v1/nodes', allNodes1, ()-> scope.fetchNodes()
    expect(scope.nodes.length).toBe(allNodes1.length)

  it 'should paginate /packages if it supports pagination', ()->
    paginateResponse @httpBackend, '/v1/packages', allPackages1, ()-> scope.fetchPackages()
    expect(scope.packages.length).toBe(allPackages1.length)

  it 'should not paginate /packages if it doesnt supports pagination', ()->
    dontPaginateResponse @httpBackend, '/v1/packages', allPackages1, ()-> scope.fetchPackages()
    expect(scope.packages.length).toBe(allPackages1.length)

  it 'should be able to list /nodes', () ->
    paginateResponse @httpBackend, '/v1/nodes', allNodes1, () -> scope.fetchNodes()

    expect(scope.nodes.length).toBe(2)
    # test both nodes
    for idx in [0,1]
      expect(@typeOf(scope.nodes[idx])).toBe('object')
      expect(scope.nodes[idx]['id']).toBe(allNodes1[idx]['id'])

  it 'should be able to access /node/xyz info (empty node)', () ->
    id = 'test'
    @httpBackend.whenGET('/v1/node/'+id).respond({
      'packages':[]
      })
    @httpBackend.expectGET('/v1/node/'+id)
    # issue the call
    scope.ensureNode(id)
    @httpBackend.flush()

    n = scope.node[id]
    # check if the first node has properties
    expect(@typeOf(n)).toBe('object')
    expect(n.id).toBe(id)
    expect(@typeOf(n.packages)).toBe('array')
    expect(n.packages.length).toBe( 0 )

  it 'should be able to access /node/xzy info (filled one)', () ->
    id = 'test'
    @httpBackend.whenGET('/v1/node/'+id).respond({
      'packages':[
        {
          'id': 'poiu',
          'name': 'accountsservice',
          'summary': 'query and manipulate user account information'
        }
      ]
      })
    @httpBackend.expectGET('/v1/node/'+id)
    # issue the call
    scope.ensureNode(id)
    @httpBackend.flush()

    n = scope.node[id]
    # check if the first node has properties
    expect(@typeOf(n)).toBe('object')
    expect(n.id).toBe(id)
    expect(@typeOf(n.packages)).toBe('array')
    expect(n.packages.length).toBe( 1 )
    expect(n.packages[0].id).toBe( 'poiu' )
    expect(n.packages[0].name).toBe( 'accountsservice' )
    expect(n.packages[0].summary).toBe( 'query and manipulate user account information' )

  it 'should be a able to fetch /packages', () ->
    ps = allPackages1
    paginateResponse @httpBackend, '/v1/packages', ps, () -> scope.fetchPackages()

    expect(scope.packages.length).toBe(ps.length)
    # test both packages
    for idx in [0,1]
      res_p = scope.packages[idx]
      expect(@typeOf(res_p)).toBe('object')
      expect(res_p.name).toBe(ps[idx].name)
      expect(res_p.versions.length).toBe(ps[idx].versions.length)

      # every package we load creates an entry in the package map
      for v in res_p.versions
        p = scope.package[v.id]
        expect(@typeOf(p)).toBe('object')
        expect(p.name).toBe(ps[idx].name)
        expect(p.version).toBe(v.version)
        expect(p.versions).toBe(undefined)

  it 'should list /packages compared to upstream repositories (by ID)', () ->
    # get repos
    paginateResponse @httpBackend, '/v1/repositories', allRepos1, () -> scope.fetchRepos()
    expect(scope.repos.length).toBe(allRepos1.length)
    # set packages list when selecting a repository
    ps = allPackages2
    scope.selectRepo(allRepos1[0])
    opts = {'query': [['repo',allRepos1[0].id],['outdated','true']]}
    dontPaginateResponse @httpBackend, '/v1/packages', ps, (() -> scope.fetchPackages()), opts
    # results
    expect(scope.allPackages.length).toBe(ps.length)
    expect(scope.packages.length).toBe(ps.length)
    # test both packages
    for idx in [0,1]
      res_p = scope.packages[idx]
      expect(@typeOf(res_p)).toBe('object')
      expect(res_p.name).toBe(ps[idx].name)
      expect(res_p.versions.length).toBe(ps[idx].versions.length)
      expect(res_p.upstream).toBe(ps[idx].upstream)

    # test if it is outdated
    expect( scope.isPackageOutdated( scope.packages[0]) ).toBe(false)
    expect( scope.isPackageOutdated( scope.packages[1]) ).toBe(true)

  it 'should list /packages compared to upstream repositories (by label)', () ->
    # get repos
    paginateResponse @httpBackend, '/v1/repositories', allRepos1, () -> scope.fetchRepos()
    expect(scope.repos.length).toBe(allRepos1.length)
    # set packages list when selecting a repository
    ps = allPackages2
    scope.selectRepoLabel(allRepos1[0].label)
    opts = {'query': [['repolabel',allRepos1[0].label],['outdated','true']]}
    dontPaginateResponse @httpBackend, '/v1/packages', ps, (() -> scope.fetchPackages()), opts
    # results
    expect(scope.allPackages.length).toBe(ps.length)
    expect(scope.packages.length).toBe(ps.length)
    # test both packages
    for idx in [0,1]
      res_p = scope.packages[idx]
      expect(@typeOf(res_p)).toBe('object')
      expect(res_p.name).toBe(ps[idx].name)
      expect(res_p.versions.length).toBe(ps[idx].versions.length)
      expect(res_p.upstream).toBe(ps[idx].upstream)

    # test if it is outdated
    expect( scope.isPackageOutdated( scope.packages[0]) ).toBe(false)
    expect( scope.isPackageOutdated( scope.packages[1]) ).toBe(true)

  it 'should only allow selecting either repo label or ID', () ->
    # get repos
    paginateResponse @httpBackend, '/v1/repositories', allRepos1, () -> scope.fetchRepos()
    expect(scope.repos.length).toBe(allRepos1.length)
    # for now...
    expect(scope.repoSelected).toEqual({})
    expect(scope.repoSelectedLabel).toBe(null)

    opts = {'query': [['repolabel',allRepos1[0].label],['outdated','true']]}
    select_by_label = () -> scope.selectRepoLabel(allRepos1[0].label)
    paginateResponse @httpBackend, '/v1/packages', allPackages1, select_by_label, opts
    expect(scope.repoSelected).toEqual({})
    expect(scope.repoSelectedLabel).toBe(allRepos1[0].label)

    opts = {'query': [['repo',allRepos1[0].id],['outdated','true']]}
    select_by_id = () -> scope.selectRepo(allRepos1[0])
    paginateResponse @httpBackend, '/v1/packages', allPackages1, select_by_id, opts
    expect(scope.repoSelected[allRepos1[0].id]).toBe(allRepos1[0])
    expect(scope.repoSelectedLabel).toBe(null)

    opts = {'query': [['repolabel',allRepos1[0].label],['outdated','true']]}
    select_by_label = () -> scope.selectRepoLabel(allRepos1[0].label)
    paginateResponse @httpBackend, '/v1/packages', allPackages1, select_by_label, opts
    expect(scope.repoSelected).toEqual({})
    expect(scope.repoSelectedLabel).toBe(allRepos1[0].label)

  it 'provides all repository labels (uniq)', () ->
    scope.repos = [
      {'label': 'a'}, {'label': 'a'},
      {'label': 'b'}
    ]
    labels = scope.repoLabels()
    expect( labels ).toContain('a')
    expect( labels ).toContain('b')
    expect( labels.length ).toBe(2)

  it 'should be able to access /package/xyz info (empty one)', () ->
    id = 'xyz'
    @httpBackend.whenGET('/v1/package/'+id).respond({})
    @httpBackend.expectGET('/v1/package/'+id)
    scope.fetchPackage(id)
    @httpBackend.flush()

    p = scope.package[id]
    expect(@typeOf(p)).toBe('object')
    expect(p.id).toBe(id)

  it 'should be able to access /package/xyz info (filled one)', () ->
    id = 'xyz'
    r = package1
    @httpBackend.whenGET('/v1/package/'+id).respond(r)
    @httpBackend.expectGET('/v1/package/'+id)
    scope.fetchPackage(id)
    @httpBackend.flush()

    p = scope.package[id]
    expect(@typeOf(p)).toBe('object')
    expect(p.id).toBe(id)
    expect(p.name).toBe(r.name)
    expect(p.uri).toBe(r.uri)
    expect(p.summary).toBe(r.summary)
    expect(p.version).toBe(r.version)
    expect(p.architecture).toBe(r.architecture)
    expect(p.provider).toBe(r.provider)
    expect(p.archive).toBe(r.archive)
    expect(@typeOf(p.nodes)).toBe('array')
    expect(p.nodes.length).toBe(r.nodes.length)

  it 'should provide all nodes if no package is selected', () ->
    scope.allNodes = allNodes1
    scope.updateNodeSelection()
    expect( scope.nodes ).toBe( scope.allNodes )

  it 'should provide only the node which has the selected package', () ->
    scope.allNodes = allNodes1
    scope.packageByName['p'] =
      'versions': [{ 'id': 'pid' }]
    scope.package['pid'] = {}
    scope.package['pid'].nodes = [ { 'id': allNodes1[0].id } ]
    scope.packageSelected['p'] = true
    scope.updateNodeSelection()
    expect( scope.nodes.length ).toBe( 1 )
    expect( scope.nodes[0].id ).toBe( allNodes1[0].id )


  it 'should provide all packages if no node is selected', () ->
    scope.allPackages = allPackages1
    scope.updatePackageSelection()
    expect( scope.packages ).toBe( scope.allPackages )

  it 'should provide only the packages assigned to a selected node', () ->
    scope.allPackages = allPackages1
    scope.node['n'] = {}
    scope.node['n'].packages = [ { 'id': allPackages1[0].versions[0].id } ]
    scope.nodeSelected['n'] = true
    scope.updatePackageSelection()
    expect( scope.packages.length ).toBe( 1 )
    expect( scope.packages[0].name ).toBe( allPackages1[0].name )


  ## Querying Repositories

  it 'should be able to [C]reate a new repository', () ->
    # when you create a new repository it should add a new position to the list to the front
    expect( scope.newRepos.length ).toBe(0)
    scope.newRepo()
    expect( scope.newRepos.length ).toBe(1)
    expect( scope.newRepos[0].id ).toBe(undefined)
    # when you click on save, it should issue an post request to the server to indicate a new element
    callResponse @httpBackend, '/v1/repositories', 'POST', 201, allRepos1[0], () -> scope.saveRepo(scope.newRepos[0])
    # make sure nothing is changed if the call was successful
    expect( scope.newRepos.length ).toBe(0)
    expect( scope.repos[0].id ).not.toBe(undefined)

  it 'should [R]ead all repositories the server has available', () ->
    paginateResponse @httpBackend, '/v1/repositories', allRepos1, () -> scope.fetchRepos()
    expect(scope.repos.length).toBe(allRepos1.length)

  it 'should be able to [U]pdate an existing repository', () ->
    # TODO: maybe remove the creation and expect it to exist already
    scope.newRepo()
    callResponse @httpBackend, '/v1/repositories', 'POST', 201, allRepos1[0], () -> scope.saveRepo(scope.newRepos[0])

    # initiate editing of a repository
    obj = scope.repos[0]
    expect(scope.editingRepo[obj.id]).toBe(undefined)
    scope.editRepo(obj)
    expect(scope.editingRepo[obj.id]).not.toBe(undefined)

    # change some property of this repository
    scope.editingRepo[obj.id].name = 'Minus Monor'

    # save the result
    res = allRepos1[0]
    res.name = 'Minus Monor'
    callResponse @httpBackend, '/v1/repositories/'+obj.id, 'PATCH', 200, res, () -> scope.saveRepo(scope.editingRepo[obj.id])

    # check if the results are correct
    expect(scope.editingRepo[obj.id]).toBe(undefined)
    obj = scope.repos[0]
    expect(obj.name).toBe('Minus Monor')

  it 'should be able to [D]elete an existing repository', () ->
    # TODO: maybe remove the creation and expect it to exist already
    scope.newRepo()
    callResponse @httpBackend, '/v1/repositories', 'POST', 201, allRepos1[0], () -> scope.saveRepo(scope.newRepos[0])
    # update the name of an existing repository
    callResponse @httpBackend, '/v1/repositories/'+scope.repos[0].id, 'DELETE', 204, null, () -> scope.deleteRepo(scope.repos[0])
    expect(scope.repos.length).toBe(0)