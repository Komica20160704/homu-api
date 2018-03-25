var isSSL = location.protocol == 'https:'
var komica = 'https://rem.komica2.net'
var image_host = '//ram.komica2.net'
var weekday = ['日', '一', '二', '三', '四', '五', '六']
var scheme = 'wss://'
if (location.protocol == 'http:') {
  scheme = 'ws://'
}
var uri = scheme + window.document.location.host + '/'
var ws = null
var isCached = false

function receivedNotify(data) {
  var blocks = data.Blocks
  var heads = data.Heads
  blocks.forEach(function(e) {
    if (e.HeadNo == followResNo) {
      followRes.receivedNotify(e)
    }
  })
}

function startWebSocket(uri) {
  ws = new WebSocket(uri)
  ws.onmessage = function(message) {
    var data = JSON.parse(message.data)
    if (data.Type == 'Notify') {
      receivedNotify(data)
    }
  }
}

startWebSocket(uri)
setInterval(function() {
  if (ws.readyState == ws.OPEN) {
    ws.send(JSON.stringify({ Event: 'KeepAlive' }))
  } else {
    startWebSocket(uri)
  }
}, 10000)

$(document).ready(function() {
  Vue.component('followBlock', {
    template: '#followBlock',
    props: {
      block: {},
    },
    methods: {
      pictureUrl: function() {
        return image_host + '/00/src/' + this.block.Picture
      },
      smallPictureUrl: function() {
        var picture = this.block.Picture.split('.')[0] + 's.jpg'
        return image_host + '/00/thumb/' + picture
      },
      setupWeekday: function(date) {
        var then = new Date(date)
        var theday = then.getDay()
        return weekday[theday]
      },
    },
  })

  window.followRes = new Vue({
    el: '#followRes',
    data: {
      Head: [],
      Bodies: [],
    },
    methods: {
      follow: function(headNo) {
        var that = this;
        $.ajax({
          method: 'GET',
          url: '/' + headNo + '?token=' + window.token,
          success: function(res) {
            that.Head = [res.Head];
            that.Bodies = res.Bodies;
            $('#followRes').fadeIn();
          }
        })
      },
      receivedNotify: function(block) {
        this.Bodies.push(block)
        responsiveVoice.speak('You got message!')
      },
    },
  })

  followRes.follow(followResNo)
})
