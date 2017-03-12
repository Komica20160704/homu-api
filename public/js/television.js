var Television = {
  element: document.getElementById('television'),
  $element: $('#television'),
  initialize: () => {
    Television.handleSizeChange()
    Television.$element.hide()
  },
  handleSizeChange: () => {
    if (window.innerWidth > 1240) {
      var width = ((window.innerWidth - 900) / 2)
      Television.$element.css('width', width)
    }
  },
  loadVideo: (element) => {
    var src = $(element).attr('data-video')
    var video = Television.$element.find('.video').get(0)
    Television.$element.show()
    video.src = src
    video.play()
  },
  close: () => {
    var video = Television.$element.find('.video').get(0)
    video.pause()
    Television.$element.hide()
  },
}

$(window).resize(Television.handleSizeChange)
$(window).ready(Television.initialize)
