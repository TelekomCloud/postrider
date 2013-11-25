'use strict'

angular.module('postriderApp', [
  'ngCookies',
  'ngSanitize',
  'restangular'
]).config (RestangularProvider) ->
  RestangularProvider.setBaseUrl 'https://localhost/v1'

$(document).foundation() if $?