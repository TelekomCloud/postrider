'use strict'

angular.module('postriderApp', [
  'ngCookies',
  'ngSanitize',
  'restangular'
]).config (RestangularProvider) ->
  RestangularProvider.setBaseUrl '/v1'

$(document).foundation() if $?