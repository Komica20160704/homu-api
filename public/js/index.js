$(document).ready(function() {
  var isSSL = location.protocol == 'https:'
  var scheme = 'wss://'
  if (location.protocol == 'http:') {
    scheme = 'ws://'
  }
  var uri = scheme + window.document.location.host + '/'
  var ws = null
  var app = null
  var isCached = false

  function receivedNotify(data) {
    var heads = data.Heads
    var headIndex = {}
    heads.forEach(function(head) {
      headIndex[head.No] = head
    })
    var blocks = data.Blocks
    blocks.forEach(function(block) {
      block.HeadId = headIndex[block.HeadNo].Id
      block.HeadContent = headIndex[block.HeadNo].Content
      app.receivedBlock(block)
    })
  }

  function startWebSocket(uri) {
    ws = new WebSocket(uri)
    ws.onmessage = function(message) {
      var data = JSON.parse(message.data)
      var isCache = data.Type == 'Cache' && !isCached
      if (data.Type == 'Notify' || isCache) {
        receivedNotify(data)
      }
      if (isCache) {
        app.loaded()
      }
    }
  }

  app = new Vue({
    el: '#app',
    data: {
      loading: true,
      blockType: 'full',
      blocks: [],
    },
    mounted: function() {
      startWebSocket(uri)
      setInterval(function() {
        if (ws.readyState == ws.OPEN) {
          ws.send(JSON.stringify({ Event: 'KeepAlive' }))
        } else {
          startWebSocket(uri)
        }
      }, 10000)
    },
    methods: {
      loaded: function() {
        this.loading = false
      },
      receivedBlock: function(block) {
        this.blocks.unshift(this.transferBlock(block))
      },
      transferBlock: function(block) {
        return {
          id: block.Id,
          headId: block.HeadId,
          isSelf: block.Id == block.HeadId,
          title: block.Title,
          name: block.Name,
          postAt: block.Date.replace(/\//g, '-') + ' ' + block.Time,
          number: block.No,
          headNumber: block.HeadNo,
          content: block.Content,
          headContent: block.HeadContent,
          picture: block.Picture,
        }
      },
    },
  })
})
