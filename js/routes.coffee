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

      .state 'members_detail',
        url: '/members/:uid'
        templateUrl: "./templates/members.detail.html"
        controller: "UserDetailCtrl as ctrl"
        resolve:
          backToState: ->
            'members'

      # .state 'members_detail.new_village',
      #   url: '/new_village'
      #   templateUrl: "./templates/villages.form.html"
      #   controller: "VillageFormCtrl as form"
      #   resolve:
      #     backToState: ->
      #       'members'


      .state 'guests',
        url: '/guests'
        templateUrl: "./templates/guests.html"
        controller: "GuestsCtrl as ctrl"

      .state 'guests_detail',
        url: '/guests/:uid'
        templateUrl: "./templates/guests.detail.html"
        controller: "UserDetailCtrl as ctrl"
        resolve:
          backToState: ->
            'guests'

      .state 'villages',
        url: '/villages'
        templateUrl: "./templates/villages.html"
        controller: "VillagesCtrl as ctrl"


]
