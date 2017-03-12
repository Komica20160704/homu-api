var index = 0;
var isClosed = false;
var followingHeadNo = null;
var block_list = [];
var komica = 'http://rem.komica.org';
var image_host = komica;
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
    var org_picture = image_host + '/00/src/' + picture;
    var small_picture = image_host + '/00/thumb/' + picture_no + 's.jpg';
    var element_a = $('<a>').attr('target', '_blank').attr('href', org_picture)
    var element_div = $('<div>').attr('data-video', org_picture).attr('onclick', 'Television.loadVideo(this)')
    var element_img = $('<img>').attr('class', 'dialog_img').attr('src', small_picture)
    if (picture.split('.')[1] == 'webm') {
      return $('<div>').append(element_div.append(element_img)).html()
    } else {
      return $('<div>').append(element_a.append(element_img)).html()
    }
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

var scheme = "ws://";
var uri = scheme + window.document.location.host + "/";
var ws;
var isCached = false;

function startWebSocket(uri) {
  ws = new WebSocket(uri);
  ws.onmessage = function(message) {
    var data = JSON.parse(message.data);
    if (data.Type == 'Notify' || (data.Type == 'Cache' && !isCached)) {
      isCached = true;
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
