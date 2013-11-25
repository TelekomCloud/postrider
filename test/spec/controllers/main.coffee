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

    nodes = [
      'node1': {
        'id': 'my1.full.fqdn',
        'packages': []
      }
    ]

    $httpBackend.whenGET("/nodes").respond(nodes);

    MainCtrl = $controller('MainCtrl', {
      $scope: scope,
      Restangular: Restangular
    })
  ))

  it 'should have a default host configured', () ->
    expect(scope.ponyExpressHost).toBe('127.0.0.1')
