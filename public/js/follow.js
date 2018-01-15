var isSSL = location.protocol == 'https:';
var komica = 'https://rem.komica2.net';
var image_host = '//p2.komica.ml';
var weekday = [
  "日",
  "一",
  "二",
  "三",
  "四",
  "五",
  "六"
];

function receivedNotify(data) {
  var blocks = data.Blocks;
  var heads = data.Heads;
  blocks.forEach(function(e) {
    if (e.HeadNo == followResNo) {
      followRes.receivedNotify(e);
    }
  });
}

var scheme = 'wss://';
if (location.protocol == 'http:') {
  scheme = 'ws://'
}
var uri = scheme + window.document.location.host + "/";
var ws;
var isCached = false;

function startWebSocket(uri) {
  ws = new WebSocket(uri);
  ws.onmessage = function(message) {
    var data = JSON.parse(message.data);
    if (data.Type == 'Notify') {
      receivedNotify(data);
    }
  };
}

startWebSocket(uri);

setInterval(function() {
  if (ws.readyState == ws.OPEN) {
    ws.send(JSON.stringify({
      Event: "KeepAlive"
    }));
  } else {
    startWebSocket(uri);
  }
}, 10000);

$( document ).ready(function() {
  Vue.component('followBlock', {
    template: '#followBlock',
    props: {
      block: Object
    },
    methods: {
      setupContent: function(content) {
        var lines = content.split('\n');
        lines.forEach(function(e, i) {
          if (e.startsWith('>')) {
            lines[i] = '<span class="reuse">' + e + '</span>';
          }
        });
        return lines.join('<br>');
      },
      setupPicture: function(picture) {
        if (picture) {
          var picture_no = picture.split('.')[0];
          var org_picture = image_host + '/00/src/' + picture;
          var small_picture = image_host + '/00/thumb/' + picture_no + 's.jpg';
          var html = '<a class="dialog-img-link" target="_blank" href="' + org_picture + '">';
          html += '<img class="dialog_img small" src="' + small_picture;
          html += '" style="max-width:125px;max-height:125px">';
          html += '<div class="dialog-img-after"></div>';
          html += '</a>';
          return html;
        } else {
          return '<div class="dialog-img-link"><img class="dialog_img small"></div>';
        }
      },
      setupWeekday: function(date) {
        var then = new Date("20" + date);
        var theday = then.getDay();
        return weekday[theday];
      }
    }
  });
  window.followRes = new Vue({
    el: '#followRes',
    data: {
      Head: [],
      Bodies: []
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
        this.Bodies.push(block);
        responsiveVoice.speak("You got message!");
      }
    }
  });
  followRes.follow(followResNo);
});
