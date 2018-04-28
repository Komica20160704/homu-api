function Television() {
  var $back = $('#television-back')
  var $element = $('#television')
  var $video = $element.find('.video')
  var $img = $element.find('.img')
  var $closeButton = $element.find('.close-button')
  var $openButton = $element.find('.open-button')
  var video = $video.get(0)
  var img = $img.get(0)

  function initialize() {
    $closeButton.click(close)
  }

  function loadImage(element) {
    var src = element.dataset.image
    img.src = src
    $openButton.attr('href', src)
    show('img')
  }

  function loadVideo(element) {
    var src = element.dataset.video
    video.src = src
    $openButton.attr('href', src)
    show('video')
    video.play()
  }

  function show(type) {
    $back.show()
    if (type == 'video') {
      $video.show()
    } else {
      $img.show()
    }
  }

  function close() {
    video.pause()
    $back.hide()
    $video.hide()
    $img.hide()
  }

  return {
    initialize: initialize,
    loadVideo: loadVideo,
    loadImage: loadImage,
    show: show,
    close: close,
  }
}

var television = new Television()
$(window).ready(television.initialize)
