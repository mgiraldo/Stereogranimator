class General

  constructor: () ->
    @idle_id = -1
    @refreshMobileClick()
    @idleTimeout() unless window.location.pathname == "/create_pe"

  refreshMobileClick: () ->
    overrides = [
      ".dim a"
      ".stereograph a"
      ".genericButtonLink"
    ]
    @mobileClick id for id in overrides

  mobileClick: (id) ->
    elem = $(id)
    elem.click (e) ->
      e.preventDefault()
      window.location.href = e.currentTarget.href

  idleTimeout: () ->
    window.addEventListener "mousemove", @resetTimer, false
    window.addEventListener "mousedown", @resetTimer, false
    window.addEventListener "keypress", @resetTimer, false
    window.addEventListener "DOMMouseScroll", @resetTimer, false
    window.addEventListener "mousewheel", @resetTimer, false
    window.addEventListener "touchmove", @resetTimer, false
    window.addEventListener "MSPointerMove", @resetTimer, false
    @resetTimer()

  resetTimer: () =>
    c = window.clearTimeout(@idle_id) #if @idle_id != -1
    @idle_id = window.setTimeout(@isIdle, 60000)
    # console.log "timer reset", c, @idle_id

  isIdle: () ->
    # console.log "idle... redirecting"
    window.location.href = "/create_pe"

$ ->
  window._gen = new General()
