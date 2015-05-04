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

      .state 'member_detail',
        url: '/members/:uid'
        templateUrl: "./templates/user.detail.html"
        controller: "MemberDetailCtrl as ctrl"


      .state 'guests',
        url: '/guests'
        templateUrl: "./templates/guests.html"
        controller: "GuestsCtrl as ctrl"

      .state 'guest_detail',
        url: '/guests/:uid'
        templateUrl: "./templates/guest.detail.html"
        controller: "GuestDetailCtrl as ctrl"

]
