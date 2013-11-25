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
    expect(scope.nodes[0]).toBe(@nodes[0]['id'])
    expect(scope.nodes[1]).toBe(@nodes[1]['id'])
