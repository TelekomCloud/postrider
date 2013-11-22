'use strict';

describe('Controller: MainCtrl', function () {

  // load the controller's module
  beforeEach(module('postriderApp'));

  var MainCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject(function ($controller, $rootScope) {
    scope = $rootScope.$new();
    MainCtrl = $controller('MainCtrl', {
      $scope: scope
    });
  }));

  it('should have a default host configured', function () {
    expect(scope.ponyExpressHost).toBe("127.0.0.1");
  });
});
