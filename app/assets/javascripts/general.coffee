class General

  constructor: () ->
    @refreshMobileClick()

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
      window.location.href = e.currentTarget.href;

$ ->
  window._gen = new General()
