function Tawawa() {
  function initialize() {
    var el = $('<div>').addClass('tawawa-point')
    $('body').append(el)
    el.mouseup(function() {
      $(this).attr('style', 'cursor: grab; cursor: -moz-grab; cursor: -webkit-grab;')
    })
    el.mousedown(function() {
      $(this).attr('style', 'cursor: grabbing; cursor: -moz-grabbing; cursor: -webkit-grabbing;')
    })
    el.click(switchState)
  }

  function switchState() {
    $('link[data-title=tawawa]')[0].disabled = true
    $('body').css('background-image', 'url("/bgs/tawawa.png")')
    $('.tawawa-point').hide()
  }

  return({
    initialize: initialize,
  })
}

$(document).ready(function() {
  var tawawa = Tawawa()
  tawawa.initialize()
  console.log('tawawa')
})
