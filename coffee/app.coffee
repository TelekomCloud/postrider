'use strict'

angular.module('postriderApp', [
  'ngCookies',
  'ngSanitize',
  'ngAnimate',
  'restangular'
]).config (RestangularProvider) ->
  RestangularProvider.setBaseUrl '/v1'

$(document).foundation() if $?