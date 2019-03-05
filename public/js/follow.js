var isSSL = location.protocol == 'https:'
var scheme = 'wss://'
if (location.protocol == 'http:') {
  scheme = 'ws://'
}
var uri = scheme + window.document.location.host + '/'
var ws = null

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
  window.followRes = new Vue({
    el: '#follow-res',
    data: {
      head: null,
      bodies: [],
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
            that.head = that.transferBlock(res.Head);
            that.bodies = res.Bodies.map(that.transferBlock);
          }
        })
      },
      receivedNotify: function(block) {
        this.bodies.push(this.transferBlock(block))
        if (this.sound) {
          responsiveVoice.speak('You got message!')
        }
      },
      transferBlock: function(block) {
        return {
          id: block.Id,
          title: block.Title,
          name: block.Name,
          postAt: block.Date.replace(/\//g, '-') + ' ' + block.Time,
          number: block.No,
          content: block.Content,
          picture: block.Picture,
        }
      },
    },
  })
  followRes.follow(followResNo)
})
