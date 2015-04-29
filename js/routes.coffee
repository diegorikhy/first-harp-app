angular.module 'app.routes', ['ui.router']

.config [
  '$stateProvider', '$urlRouterProvider'
  ($stateProvider, $urlRouterProvider)->

    $urlRouterProvider.otherwise "/"

    $stateProvider
      .state 'home',
        url: "/"
        template: ""

      .state 'state1',
        url: "/state1"
        templateUrl: "templates/state1.html"

      .state 'state1.list',
          url: '/list'
          templateUrl: 'templates/state1.list.html'
          controller: ['$scope', ($scope)->
            $scope.items = ['A', 'List', 'Of', 'Items']
          ]

      .state 'state2',
        url: '/state2'
        templateUrl: 'templates/state2.html'

      .state 'state2.list',
        url: '/list'
        templateUrl: 'templates/state2.list.html'
        controller: ['$scope', ($scope)->
          $scope.things = ['A', 'Set', 'Of', 'Things']
        ]

]
