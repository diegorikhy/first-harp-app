angular.module 'app.routes', ['ui.router']

.config [
  '$stateProvider', '$urlRouterProvider', '$locationProvider'
  ($stateProvider, $urlRouterProvider, $locationProvider)->
    $locationProvider.html5Mode true

    $urlRouterProvider.otherwise "/"

    $stateProvider
      .state 'home',
        url: "/"

      .state 'members',
        url: '/members'
        templateUrl: "./templates/members.html"
        controller: "MembersCtrl as ctrl"

      .state 'guests',
        url: '/guests'
        templateUrl: "./templates/guests.html"
        controller: "GuestsCtrl as ctrl"

]
