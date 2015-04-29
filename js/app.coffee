angular.module 'app', ['ui.router','app.routes', 'duScroll', 'ui.bootstrap', 'ngAnimate']

.config [
  '$locationProvider'
  ($locationProvider)->
    $locationProvider.html5Mode true
]

.run [
  "$rootScope", "ModalSrv"
  ($rootScope, ModalSrv)->
    $rootScope.$on '$stateChangeSuccess', (e,state)->
      ModalSrv.active = (state.name != 'home')
]

.controller "AppCtrl", [
  "Menu", "ModalSrv", "$document"
  (Menu, ModalSrv, $document)->
    vm = @
    vm.menu = Menu
    vm.modal = ModalSrv
    vm.scrollTop = ->
      $document.scrollTopAnimated(0, 500)

    return
]

.factory "toggler", ->
    class
      constructor: (@attrName)->
        @[@attrName] = true
      toggle: ->
        if @[@attrName] then @open() else @close()
      close: ->
        @[@attrName] = true
      open: ->
        @[@attrName] = false

.factory "ModalSrv", [ 'toggler', (tg)-> new tg('active') ]
.factory "Menu",     [ 'toggler', (tg)-> new tg('collapse') ]


.directive "navbarFixedTop", ["$timeout", ($timeout)->
  restrict: 'C'
  link: (scope, element, attrs)->
    docElem = document.documentElement
    didScroll = false
    changeHeaderOn = 300

    scrollPage = ->
      sy = window.pageYOffset || docElem.scrollTop

      if sy >= changeHeaderOn
        element.addClass 'navbar-shrink'
      else
        element.removeClass 'navbar-shrink'

      didScroll = false;

    scrollFn = ->
      if !didScroll
        didScroll = true
        $timeout scrollPage, 250

    window.addEventListener 'scroll', scrollFn, false

    scope.$on "$destroy", ->
      window.removeEventListener 'scroll', scrollFn
]








