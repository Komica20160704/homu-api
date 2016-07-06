var index = 0;
var isClosed = false;
var block_list = [];
var komica = 'http://homu.komica.org';
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
  var html = '<div id="dialog' + id + '" class="dialog" style="">';
  html += setupMessage(id, block, heads);
  html += setupData(id, block);
  html += setupPicture(block.Picture);
  html += setupContent(id, block.Content);
  html += '</div>';
  return html;
}

function setupMessage(id, block, heads) {
  var url = komica + '/00/index.php?res=' + block.HeadNo;
  var html = '<div style="margin-top:8;margin-left:8;">';
  if (block.No == block.HeadNo) {
    html += block.Id + '發表了一篇';
    html += '<a href = "' + url + '" target = "_blank"><b>新文章</b></a>';
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
  html += '<font color="#cc1105" size="+1"><b>' + block.Title + '</b></font>';
  html += ' <font color="#117743"><b>' + block.Name + '</b></font>';
  html += ' <font>' + date_time + id_no + '</font></div>';
  return html;
}

function showHideContent(id) {
  $('#dialog_show_button' + id).hide();
  $('#dialog_hide_content' + id).show();
}

function setTooLongContent(id, lines) {
  var visiable = lines.splice(0, 4).join('<br>');
  var showButton = '<a id="dialog_show_button' + id + '" ';
  showButton += 'onclick="showHideContent(' + id + ')" ';
  showButton += 'href="#dialog_show_button' + id + '"><br>顯示完整內容</a>';
  var unvisiable = '<span id="dialog_hide_content' + id + '" ';
  unvisiable += 'style="display:none;">';
  unvisiable += '<br>' + lines.join('<br>') + '</span>';
  return visiable + showButton + unvisiable;
}

function setupContent(id, content) {
  var lines = content.split('\n');
  lines.forEach(function(e, i) {
    if (e.startsWith('>')) {
      lines[i] = '<span style="color:rgb(120,153,34);">' + e + '</span>';
    }
  });
  var html = '<div class="dialog_content">';
  if (lines.length > 5) {
    html += setTooLongContent(id, lines);
  } else {
    html += lines.join('<br>');
  }
  html += '</div>';
  return html;
}

function setupPicture(picture) {
  if (picture) {
    var picture_no = picture.split('.')[0];
    var org_picture = komica + '/00/src/' + picture;
    var small_picture = komica + '/00/thumb/' + picture_no + 's.jpg';
    var html = '<a target="_blank" href="' + org_picture + '">';
    html += '<img class="dialog_img" src="' + small_picture;
    html += '" style="width:125px;"></a>';
    return html;
  } else {
    return '<img class="dialog_img">';
  }
}

function receivedNotify(data) {
  var blocks = data.Blocks;
  var heads = data.Heads;
  var html = "";
  var id_list = [];
  blocks.forEach(function(e) {
    var id = index++;
    html = createDialog(id, e, heads) + html;
    id_list.push("#dialog" + id);
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
  while (block_list.length > 100) {
    var id = block_list.shift();
    $(id).remove();
  }
}

var scheme = "ws://";
var uri = scheme + window.document.location.host + "/";
var ws = new WebSocket(uri);

ws.onmessage = function(message) {
  var data = JSON.parse(message.data);
  if (data.Type == 'Notify' || data.Type == 'Cache') {
    receivedNotify(data);
  }
};

function onWebSocketClosed() {
  if (!isClosed) {
    var message = '與伺服器失去連線!\n可能為伺服器例行作業，請稍後再重新連接此頁。\n若仍無法開啟網頁，請聯絡網站相關人員。';
    $("#block-container")[0].innerHTML = message + $("#block-container")[0].innerHTML;
    isClosed = true;
  }
}

ws.onclose = onWebSocketClosed;

setInterval(function() {
  if (ws.readyState == ws.OPEN) {
    ws.send(JSON.stringify({
      Event: "KeepAlive"
    }));
  } else {
    onWebSocketClosed();
  }
}, 10000);
