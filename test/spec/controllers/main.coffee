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


  # The tests:
  #-----------

  it 'should have no default host configured', () ->
    expect(scope.ponyExpressHost).toBe(undefined)

  paginateResponse = (httpBackend, baseUrl, response, action, limit=50)->
    # 1. working pagination
    #    it will request page 1, get it,
    #    and request page 2 and finish
    url = "#{baseUrl}?limit=#{limit}&page=1"
    httpBackend.whenGET(url).respond(response)
    httpBackend.expectGET(url)
    url = "#{baseUrl}?limit=#{limit}&page=2"
    httpBackend.whenGET(url).respond(410,'Gone')
    httpBackend.expectGET(url)
    # take the action and flush the backend
    action()
    httpBackend.flush()

  dontPaginateResponse = (httpBackend, baseUrl, response, action, limit=50)->
    # 2. no pagination
    #    it will request page 1, won't get it
    #    and try without pagination
    url = "#{baseUrl}?limit=#{limit}&page=1"
    httpBackend.whenGET(url).respond(410,'Gone')
    httpBackend.expectGET(url)
    url = "#{baseUrl}"
    httpBackend.whenGET(url).respond(response)
    httpBackend.expectGET(url)
    # take the action and flush the backend
    action()
    httpBackend.flush()

  it 'should paginate /nodes if it supports pagination', ()->
    paginateResponse @httpBackend, '/v1/nodes', [], () -> scope.fetchNodes()
    expect(scope.nodes.length).toBe(0)

  it 'should not paginate /nodes if it doesnt supports pagination', ()->
    dontPaginateResponse @httpBackend, '/v1/nodes', [], ()-> scope.fetchNodes()
    expect(scope.nodes.length).toBe(0)

  it 'should paginate /packages if it supports pagination', ()->
    paginateResponse @httpBackend, '/v1/packages', [], ()-> scope.fetchPackages()
    expect(scope.packages.length).toBe(0)

  it 'should not paginate /packages if it doesnt supports pagination', ()->
    dontPaginateResponse @httpBackend, '/v1/packages', [], ()-> scope.fetchPackages()
    expect(scope.packages.length).toBe(0)

  it 'should be able to list /nodes', () ->
    nodes = [
      { 'id': 'my1.full.fqdn' },
      { 'id': 'my2.full.fqdn' }
    ]
    paginateResponse @httpBackend, '/v1/nodes', nodes, () -> scope.fetchNodes()

    expect(scope.nodes.length).toBe(2)
    # test both nodes
    for idx in [0,1]
      expect(@typeOf(scope.nodes[idx])).toBe('object')
      expect(scope.nodes[idx]['id']).toBe(nodes[idx]['id'])

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
    expect(p.nodes).toBe(r.nodes)

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
