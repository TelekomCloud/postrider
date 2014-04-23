'use strict'

angular.module('postriderApp', [
  'ngCookies',
  'ngSanitize',
  'ngAnimate',
  'restangular'
]).config (RestangularProvider) ->
  RestangularProvider.setBaseUrl '/v1'

if $?
  # initialize foundation
  $(document).foundation({
    reveal : {
      animation_speed: 100,
      animation: 'fade'
    }
  })