angular.module 'app', ['ui.router','app.routes', 'duScroll', 'ui.bootstrap', 'ngAnimate', 'firebase']

.constant 'FIREBASE_URL', 'https://united2win.firebaseio.com/'

.run [
  "$rootScope", "ModalSrv"
  ($rootScope, ModalSrv)->
    $rootScope.$on '$stateChangeSuccess', (e,state)->
      ModalSrv.active = (state.name != 'home')
]

.controller "AppCtrl", [
  "Menu", "ModalSrv", "$document", 'loginSrv'
  (Menu, ModalSrv, $document, loginSrv)->
    vm = @
    vm.menu = Menu
    vm.modal = ModalSrv
    vm.loginSrv = loginSrv
    vm.scrollTop = ->
      $document.scrollTopAnimated(0, 500)

    return
]

.factory "toggler", ->
  class
    constructor: (attrs, @onOpen=angular.noop, @onClose=angular.noop)->
      angular.extend @, attrs
      @attrName = 'open' unless 'attrName' of attrs
      @[@attrName] = true unless @attrName of attrs
    toggle: ->
      if @[@attrName] then @open() else @close()
    close: ->
      @[@attrName] = true
      @onClose(arguments...)
    open: ->
      @[@attrName] = false
      @onOpen(arguments...)

.factory "ModalSrv", [
  'toggler',
  (tg)->
    new tg
      attrName: 'active'
      goBackTo: undefined
]

.factory "Menu",     [ 'toggler', (tg)-> new tg(attrName: 'collapse') ]

.factory "socialExtractor", ->
  extractors =
    facebook: (data)->
      obj = {}
      obj.provider          = data.provider
      obj.name              = data.facebook.displayName
      obj.email             = data.facebook.email if data.facebook.email

      if profile = data.facebook.cachedUserProfile
        obj.gender       = profile.gender
        obj.locale       = profile.locale
        obj.profile_url  = profile.link
        obj.picture_url  = profile.picture.data.url if profile.picture?.data?.url?

      obj

  (data)-> extractors[data.provider](data)

.factory "loginSrv", [
  'fbRef', '$firebaseAuth', '$firebaseObject', 'socialExtractor'
  (ref, $firebaseAuth, $firebaseObject, socialExtractor)->
    service =
      auth: $firebaseAuth(ref)

      logout: ->
        @me.$destroy()
        @me = undefined
        @checkData()
        @auth.$unauth()

      login: (provider='facebook')->
        @auth.$authWithOAuthPopup provider

      loadMe: (data)->
        $firebaseObject(ref.child("users/#{data.uid}")).$loaded()
          .then (user)=>
            @me = user
            @checkData()

            @me.$watch =>
              @checkData()
              unless @me.role
                @logout()

            unless @me.role
              angular.extend @me, socialExtractor(data)
              @me.role = 'guest'
              @me.admin = false
              @me.$save().then =>
                ref.child("guests/#{@me.$id}").set(true)

      checkData: ->
        @isMember = (@me?.role == 'member')
        @isAdmin = @me?.admin


    service.auth.$onAuth (authData)->
      if authData
        service.session = authData
        service.loadMe(authData)
      else
        service.session = undefined

    service
]

.filter "firstName", ->
  (fullName)-> fullName.split(" ")[0]


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

.controller "MembersCtrl", [
  'fbRef', '$firebaseArray', '$state', 'ModalSrv', 'loginSrv','User'
  (ref, $firebaseArray, $state, ModalSrv, loginSrv, User)->
    ModalSrv.goBackTo = undefined

    ctrl = @
    ctrl.loading = true

    $firebaseArray(ref.child('users').orderByChild('role').equalTo('member')).$loaded()
      .then (members)->
        ctrl.loading = false
        ctrl.members = members

      .catch (err)->
        ctrl.loading = false
        if err.code == 'PERMISSION_DENIED'
          ctrl.erro = "Desculpe, mas você não tem permissão para acessar esta lista"
        else
          $state.go 'home'

    ctrl.toggleAdmin = (member)->
      return unless loginSrv.isAdmin
      return if (loginSrv.me.$id == member.$id) && !confirm('Você não poderá mais gerenciar o clan. Tem certeza?')
      User.admin.toggle(member)


    ctrl.ban = (member)->
      User.ban(member)

    return
]

.controller "GuestsCtrl", [
  'fbRef', '$firebaseArray', 'toggler', '$state', 'ModalSrv', 'User'
  (ref, $firebaseArray, toggler, $state, ModalSrv, User)->
    ModalSrv.goBackTo = undefined
    ctrl = @
    ctrl.loading = true

    $firebaseArray(ref.child('users').orderByChild('role').equalTo('guest')).$loaded()
      .then (coll)->
        ctrl.loading = false
        ctrl.guests = coll
      .catch (err)->
        ctrl.loading = false
        if err.code == 'PERMISSION_DENIED'
          ctrl.erro = "Desculpe, mas você não tem permissão para acessar esta lista"
        else
          $state.go 'home'

    ctrl.banned = new toggler
      attrName: 'visible'
      class: 'fa-eye-slash'
      visible: false
      ->
        @class = 'fa-eye-slash'
      ->
        unless @lista
          @loading = true
          $firebaseArray(ref.child('users').orderByChild('role').equalTo('banned')).$loaded()
            .then (coll)=>
              @loading = false
              @lista = coll
            .catch (err)=>
              @loading = false

        @class = 'fa-eye'

    ctrl.ban = (guest)->
      User.ban(guest)

    ctrl.unban = (guest)->
      User.unban(guest)

    ctrl.accept = (guest)->
      User.became_member(guest)

    return
]

.factory 'fbRef', [
  'FIREBASE_URL'
  (url)->
    new Firebase url
]

.factory "User", [
  'fbRef', '$firebaseObject', 'loginSrv'
  (ref, $firebaseObject, loginSrv)->

    admin:
      toggle: (member)->
        return unless loginSrv.isAdmin
        if member.admin
          @revoke(member)
        else
          @grant(member)

      grant: (member)->
        return unless loginSrv.isAdmin
        uid = member.$id
        ref.child("users/#{uid}/admin").set true
        ref.child("admins/#{uid}").set true

      revoke: (member)->
        return unless loginSrv.isAdmin
        uid = member.$id
        ref.child("users/#{uid}/admin").set false
        ref.child("admins/#{uid}").remove()

    unban: (member)->
      return unless loginSrv.isAdmin
      uid = member.$id
      ref.child("users/#{uid}/role").set 'guest'

    ban: (member)->
      return unless loginSrv.isAdmin
      uid = member.$id
      ref.child("members/#{uid}").remove()
      ref.child("guests/#{uid}").set true
      ref.child("users/#{uid}/role").set 'banned'
      @admin.revoke(member)

    became_guest: (member)->
      return unless loginSrv.isAdmin
      uid = member.$id
      ref.child("members/#{uid}").remove()
      ref.child("guests/#{uid}").set true
      ref.child("users/#{uid}/role").set 'guest'
      @admin.revoke(member)

    became_member: (member)->
      return unless loginSrv.isAdmin
      uid = member.$id
      ref.child("guests/#{uid}").remove()
      ref.child("members/#{uid}").set true
      ref.child("users/#{uid}/role").set 'member'

    find: (uid, fn, fnCatch)->
      $firebaseObject(ref.child("users/#{uid}")).$loaded()
        .then fn
        .catch fnCatch
]

.controller "UserDetailCtrl", [
  'User', '$stateParams', 'ModalSrv', 'backToState'
  (User, $stateParams, ModalSrv, backToState)->
    ModalSrv.goBackTo = backToState
    ctrl = @
    ctrl.loading = true

    User.find $stateParams.uid,
      (user)=>
        ctrl.loading = false
        ctrl.user = user
      (err)=>
        ctrl.loading = false
        ctrl.error = err

    ctrl
]
