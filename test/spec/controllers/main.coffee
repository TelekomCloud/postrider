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

  it 'should have no default host configured', () ->
    expect(scope.ponyExpressHost).toBe(undefined)

  it 'should be able to list /nodes', () ->
    nodes = [
      { 'id': 'my1.full.fqdn' },
      { 'id': 'my2.full.fqdn' }
    ]
    @httpBackend.whenGET('/v1/nodes').respond(nodes)
    @httpBackend.expectGET('/v1/nodes')
    scope.fetchNodes()
    @httpBackend.flush()

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
    packages = [
      { 'id': 'xx' },
      { 'id': 'yy' }
    ]
    @httpBackend.whenGET('/v1/packages').respond(packages)
    @httpBackend.expectGET('/v1/packages')
    scope.fetchPackages()
    @httpBackend.flush()

    expect(scope.packages.length).toBe(2)
    # test both packages
    for idx in [0,1]
      expect(@typeOf(scope.packages[idx])).toBe('object')
      expect(scope.packages[idx]['id']).toBe(packages[idx]['id'])

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
    r = {
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
