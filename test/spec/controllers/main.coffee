'use strict'

describe 'Controller: MainCtrl', ()->

  # load the required module
  beforeEach(angular.mock.module("restangular"));

  # load the controller's module
  beforeEach(module('postriderApp'))

  # Initialize the controller and a mock scope
  beforeEach( inject( ($injector, $controller, $rootScope) ->
    scope = $rootScope.$new();
    Restangular = $injector.get("Restangular");
    $httpBackend = $injector.get("$httpBackend");

    # reliably determine object types
    # http://stackoverflow.com/questions/7390426/better-way-to-get-type-of-a-javascript-variable
    @typeOf = (obj) ->
      ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

    @nodes = [
      { 'id': 'my1.full.fqdn' },
      { 'id': 'my2.full.fqdn' }
    ]

    $httpBackend.whenGET("/nodes").respond(@nodes);

    MainCtrl = $controller('MainCtrl', {
      $scope: scope,
      Restangular: Restangular
    })
  ))

  it 'should have a default host configured', () ->
    expect(scope.ponyExpressHost).toBe('127.0.0.1')

  it 'should be able to list /nodes', () ->
    expect(scope.nodes.length).toBe(2)
    # test both nodes
    for idx in [1,2]
      expect(@typeOf(scope.nodes[idx])).toBe('object')
      expect(scope.nodes[idx]['id']).toBe(@nodes[idx]['id'])

  it 'should be able to access /node/xyz info', () ->
    # check if the first node has no nodes
    expect(@typeOf(scope.nodes[0])).toBe('object')
    expect(scope.nodes[0]['id']).toBe(@nodes[0]['id'])
    expect(scope.nodes[0]['packages'].length).toBe(0)
