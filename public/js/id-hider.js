function IdHinder() {
  var ids = []
  var $el = $('#id-hider')

  function initialize() {
    $('.new-button').click(function() {
      var id = $('.new-id').val()
      addId({id: id})
    })

    $el.find('.close').click(function() {
      var x = $el.find('.close')
      var hiding = x.data('hide')
      if (hiding) {
        $el.removeClass('hide')
        $('.new-id-row').show()
        $('.id-rows').show()
        x.data('hide', '')
        x.text('[X]')
      } else {
        $el.addClass('hide')
        $('.new-id-row').hide()
        $('.id-rows').hide()
        x.data('hide', 'hiding')
        x.text('[+]')
      }
      window.gtag('event', 'toggle', { 'event_category': 'idHider' })
    })
    resize()
  }

  function addId(id) {
    if (!isHideId(id.id)) {
      ids.push(id)
      updateView()
    }
    window.gtag('event', 'addId', { event_category: 'idHider', homu_id: id })
  }

  function removeId(el) {
    var id = $(el).data('id')
    ids = _.reject(ids, function (i) {
      return i.id == id
    })
    updateView()
    window.gtag('event', 'removeId', { event_category: 'idHider', homu_id: id })
  }

  function updateView() {
    $('.id-rows').remove()
    ids.forEach(function (id) {
      var element = $('<div>').attr('class', 'id-rows').append('ID:').append(id.id)
      var del_button = $('<button>').attr('class', 'del').attr('onclick', 'id_hider.removeId(this)').data('id', id.id).text('刪除')
      $el.append(element.append(del_button))
    })
  }

  function isHideId(id) {
    result = ids.find(function (i) {
      return i.id == id
    })
    if (result) {
      return true
    } else {
      return false
    }
  }

  function resize() {
    if (window.innerWidth > 1240) {
      var width = ((window.innerWidth - 900) / 2)
      $el.css('width', width)
    }
  }

  return({
    ids: ids,
    initialize: initialize,
    addId: addId,
    removeId: removeId,
    isHideId: isHideId,
    resize: resize,
  })
}

var id_hider = IdHinder()

$(window).resize(id_hider.resize)
$(window).ready(id_hider.initialize)
