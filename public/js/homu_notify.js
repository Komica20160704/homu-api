var isSSL = location.protocol == 'https:';
var index = 0;
var isClosed = false;
var followingHeadNo = null;
var block_list = [];
var komica = 'https://rem.komica2.net';
var image_host = '//ram.komica2.net';
var max_data_count = 100;
var weekday = [
  "日",
  "一",
  "二",
  "三",
  "四",
  "五",
  "六"
];

function createDialog(id, block, heads) {
  var then = new Date("20" + block.Date);
  var theday = then.getDay();
  var classNames = ['dialog'];
  if (block.No == block.HeadNo) { classNames.push('head'); }
  var html = '<div id="dialog' + id + '" class="' + classNames.join(' ') + '">';
  html += setupMessage(id, block, heads);
  html += setupData(id, block);
  html += setupPicture(block.Picture);
  html += setupContent(id, block.Content);
  html += '</div>';
  return html;
}

function setupMessage(id, block, heads) {
  var url = komica + '/00/pixmicat.php?res=' + block.HeadNo;
  var html = '<div style="margin-top:8;margin-left:8;">';
  var follow = ' [<a href="./follow/' + block.HeadNo + '" target="_blank">追蹤</a>]';
  if (block.No == block.HeadNo) {
    html += block.Id + '發表了一篇';
    html += '<a href = "' + url + '" target = "_blank"><b>新文章</b></a>';
    html += follow;
  } else {
    var head;
    heads.forEach(function(e) {
      if (e.No == block.HeadNo) {
        head = e;
      }
    });
    html += block.Id + '回應了';
    if (head.Id == block.Id) {
      html += '自己的';
    }
    html += '<a href = "' + url + '" target = "_blank"><b>討論串</b></a>';
    html += follow;
    html += '<div class="head_block">';
    html += '>>No.' + head.No + ' ID:' + head.Id + ': '
    html += head.Content.split('\n').join(' ') + '</div>';
  }
  html += '</div>';
  return html;
}

function setupData(id, block) {
  var then = new Date("20" + block.Date);
  var theday = then.getDay();
  var date_time = block.Date + "(" + weekday[theday] + ")" + block.Time;
  var id_no = " ID:" + block.Id + " No." + block.No;
  var html = '<hr class="split_line"><div>'
  html += '<font class="title" size="+1"><b>' + block.Title + '</b></font>';
  html += ' <font class="name"><b>' + block.Name + '</b></font>';
  html += ' <font>' + date_time + id_no + '</font></div>';
  return html;
}

function showHideContent(id) {
  $('#dialog_show_button' + id).hide();
  $('#dialog_hide_content' + id).show();
}

function setTooLongContent(id, lines) {
  var visiable = lines.splice(0, 4)
  var showButton = $('<a>').attr('id', 'dialog_show_button' + id)
  showButton.attr('onclick', 'showHideContent(' + id + ')')
  showButton.attr('href', '#dialog_show_button' + id)
  showButton.text('顯示完整內容')
  var unvisiable = $('<span>').attr('id', 'dialog_hide_content' + id)
  unvisiable.append(lines)
  unvisiable.hide()
  return visiable.concat([showButton, unvisiable])
}

function setupContent(id, content) {
  var lines = content.split('\n')
  var contentElement = $('<div>').addClass('dialog-content')
  var lineElements = lines.map(function(line, index) {
    var element = $('<div>').text(line)
    if (line.startsWith('>')) { element.addClass('reuse') }
    return element
  })
  if (lines.length > 5) {
    contentElement.append(setTooLongContent(id, lineElements))
  } else {
    contentElement.append(lineElements)
  }
  return $('<div>').append(contentElement).html()
}

function setupPicture(picture) {
  if (picture) {
    var picture_no = picture.split('.')[0];
    var org_picture = image_host + '/00/src/' + picture;
    var small_picture = image_host + '/00/thumb/' + picture_no + 's.jpg';
    var element_a = $('<a>').attr('class', 'dialog-img-link').attr('target', '_blank').attr('href', org_picture)
    var element_div = $('<div>').attr('class', 'dialog-img-link').attr('data-video', org_picture).attr('onclick', 'Television.loadVideo(this)')
    var element_img = $('<img>').attr('class', 'dialog-img').attr('src', small_picture)
    var element_img_after = $('<div>').attr('class', 'dialog-img-after')
    if (picture.split('.')[1] == 'webm') {
      return $('<div>').append(element_div.append(element_img).append(element_img_after)).html()
    } else {
      return $('<div>').append(element_a.append(element_img).append(element_img_after)).html()
    }
  } else {
    return '<div class="dialog-img-link"><img class="dialog-img small"></div>';
  }
}

function receivedNotify(data) {
  var blocks = data.Blocks;
  var heads = data.Heads;
  var html = "";
  var id_list = [];
  blocks.forEach(function(e) {
    if (window.id_hider && id_hider.isHideId(e.Id)) {
      return
    }
    var id = index++;
    html = createDialog(id, e, heads) + html;
    id_list.push("#dialog" + id);
    if (e.HeadNo == followingHeadNo) {
      followRes.receivedNotify(e);
    }
  });
  $("#block-container")[0].innerHTML = html + $("#block-container")[0].innerHTML;
  if (data.Type == 'Notify') {
    id_list.forEach(function(e, i) {
      $(e).hide();
      setTimeout(function() {
        $(e).fadeIn();
      }, i * 500);
    });
  }
  block_list = block_list.concat(id_list);
  while (block_list.length > max_data_count) {
    var id = block_list.shift();
    $(id).remove();
  }
}

var scheme = 'ws://';
if (isSSL) {
  scheme = 'wss://'
}
var uri = scheme + window.document.location.host + "/";
var ws;
var isCached = false;

function startWebSocket(uri) {
  ws = new WebSocket(uri);
  ws.onmessage = function(message) {
    var data = JSON.parse(message.data);
    if (data.Type == 'Notify' || (data.Type == 'Cache' && !isCached)) {
      isCached = true;
      $('#loader').hide();
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
