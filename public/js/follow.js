var isSSL = location.protocol == 'https:'
var komica = 'https://ram.komica2.net'
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
    template: '#follow-block',
    props: {
      isHead: false,
      block: {},
    },
    created: function() {
      this.hasPicture = !!this.block.Picture
    },
    methods: {
      isWebm: function() {
        if (this.hasPicture) {
          return this.block.Picture.split('.')[1] == 'webm'
        }
      },
      pictureUrl: function() {
        if (this.hasPicture) {
          return image_host + '/00/src/' + this.block.Picture
        }
      },
      smallPictureUrl: function() {
        if (this.hasPicture) {
          var picture = this.block.Picture.split('.')[0] + 's.jpg'
          return image_host + '/00/thumb/' + picture
        }
      },
      setupWeekday: function(date) {
        var then = new Date(date)
        var theday = then.getDay()
        return weekday[theday]
      },
      lineClass: function(line) {
        var classes = ['line']
        if (line.startsWith('>')) {
          classes.push('reuse')
        }
        return classes.join(' ')
      },
    },
  })

  window.followRes = new Vue({
    el: '#follow-res',
    data: {
      Head: [],
      Bodies: [],
      sound: true,
    },
    mounted: function() {
      this.$el.querySelector('.nav').style.display = ''
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
            $('#follow-res').fadeIn();
          }
        })
      },
      receivedNotify: function(block) {
        this.Bodies.push(block)
        if (this.sound) {
          responsiveVoice.speak('You got message!')
        }
      },
    },
  })

  followRes.follow(followResNo)
})
