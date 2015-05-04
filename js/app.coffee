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
        @auth.$unauth()

      login: (provider='facebook')->
        @auth.$authWithOAuthPopup provider

      loadMe: (data)->
        $firebaseObject(ref.child("users/#{data.uid}")).$loaded()
          .then (user)=>
            @me = user
            @me.$watch => @logout() unless @me.role

            unless @me.role
              angular.extend @me, socialExtractor(data)
              @me.role = 'guest'
              @me.admin = false
              @me.$save().then =>
                ref.child("guests/#{@me.$id}").set({banned:false, name: @me.name})

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
  'fbRef', '$firebaseArray', '$state', 'ModalSrv',
  (ref, $firebaseArray, $state, ModalSrv)->
    ModalSrv.goBackTo = undefined

    ctrl = @
    ctrl.loading = true

    $firebaseArray(ref.child('members')).$loaded()
      .then (members)->
        ctrl.loading = false
        ctrl.members = members

      .catch (err)->
        ctrl.loading = false
        if err.code == 'PERMISSION_DENIED'
          ctrl.erro = "Desculpe, mas você não tem permissão para acessar esta lista"
        else
          $state.go 'home'

    return
]

.controller "GuestsCtrl", [
  'fbRef', '$firebaseArray', 'toggler', '$state', 'ModalSrv'
  (ref, $firebaseArray, toggler, $state, ModalSrv)->
    ModalSrv.goBackTo = undefined
    ctrl = @
    ctrl.loading = true

    $firebaseArray(ref.child('guests')).$loaded()
      .then (guests)->
        ctrl.loading = false
        ctrl.guests = guests
        ctrl.banned.check()

        ctrl.guests.$watch ->
          ctrl.banned.check()

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
      exists: false
      check: ->
        @exists = (ctrl.guests.filter((e)-> JSON.parse(e.banned)).length > 0)
      -> @class = 'fa-eye-slash'
      -> @class = 'fa-eye'

    ctrl.ban = (guest)->
      guest.banned = true
      ctrl.banned.check()
      ctrl.guests.$save(guest)

    ctrl.unban = (guest)->
      guest.banned = false
      ctrl.banned.check()
      ctrl.guests.$save(guest)

    ctrl.accept = (guest)->
      memory =
        uid: guest.$id
        name: guest.name
        banned: guest.banned

      ctrl.guests.$remove(guest).then ->
        ref.child("guests/#{memory.uid}").remove (err)->
          unless err?
            ref.child("members/#{memory.uid}").set
              since: Firebase.ServerValue.TIMESTAMP
              (err)->
                unless err?
                  ref.child("users/#{memory.uid}/role").set("member")
                else
                  console.log 'Member was not created', err
                  # rollback recreate guest
                  ref.child("guests/#{memory.uid}").set
                    name: memory.name
                    banned: memory.banned
          else
            console.log 'Guest was not destroyed', err

    return
]

.factory 'fbRef', [
  'FIREBASE_URL'
  (url)->
    new Firebase url
]

.factory "User", [
  'fbRef', '$stateParams', '$firebaseObject'
  (ref, $stateParams, $firebaseObject)->

    find: (uid, fn, fnCatch)->
      $firebaseObject(ref.child("users/#{uid}")).$loaded()
        .then fn
        .catch fnCatch
]

.controller "GuestDetailCtrl", [
  'User', '$stateParams', 'ModalSrv'
  (User, $stateParams, ModalSrv)->
    ModalSrv.goBackTo = 'guests'
    ctrl = @
    ctrl.loading = true

    User.find $stateParams.uid,
      (user)=>
        ctrl.loading = false
        ctrl.user = user
      (err)=>
        ctrl.loading = false
        console.log err
        ctrl.error = err

    ctrl
]

.controller "MemberDetailCtrl", [
  'User', '$stateParams', 'ModalSrv'
  (User, $stateParams, ModalSrv)->
    ModalSrv.goBackTo = 'members'
    ctrl = @
    ctrl.loading = true

    User.find $stateParams.uid,
      (user)=>
        ctrl.loading = false
        ctrl.user = user
      (err)=>
        ctrl.loading = false
        console.log err
        ctrl.error = err

    ctrl
]

