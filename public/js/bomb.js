var h = hyperapp.h
var root = document.getElementById('root')
var end = new Date('2018/1/1')
var newSecond = function() {
  var now = new Date()
  return Math.floor((end - now) / 1000)
}
var state = {
  diff: newSecond(),
  message: '',
  safe: isPass,
  sec: '',
  messages: messages.sort().reverse(),
}
var actions = {
  safe: function(password) {
    return function() {
      return { safe: true, sec: password }
    }
  },
  setMessage: function(message) {
    return function() {
      return { message: message }
    }
  },
  addMessage: function(message) {
    return function(state) {
      return { messages: state.messages.concat(message) }
    }
  },
  countSecond: function() {
    return function() {
      return { diff: newSecond() }
    }
  },
  guestPassword: _.throttle(function() {
    app.setMessage('')
    var passwordInput = document.getElementById('password-input')
    var password = passwordInput.value
    passwordInput.value = ''
    var success = KJUR.jws.JWS.verifyJWT(token, password, {alg: ['HS256']})
    if (success) {
      app.setMessage('...')
      $.ajax({
        method: 'POST',
        data: { secret: password },
        success: function(result) {
          if (!result.success) {
            app.setMessage(result.message)
          } else {
            app.setMessage('密碼正確，炸彈被解除了！')
            app.safe(password)
          }
        },
      })
    } else {
      app.setMessage('密碼錯誤')
    }
  }, 1000),
  sendMessage: _.throttle(function(sec) {
    var nameInput = document.getElementById('name-input')
    var messageInput = document.getElementById('message-input')
    var header = JSON.stringify({ alg: 'HS256', typ: 'JWT' })
    var payload = JSON.stringify({ name: nameInput.value, message: messageInput.value })
    var token = KJUR.jws.JWS.sign('HS256', header, payload, sec)
    $.ajax({
      url: '/2018bomb/messages',
      method: 'POST',
      data: { token: token },
      success: function(result) {
        if (!result.success) {
          app.setMessage(result.message)
        } else {
          app.addMessage(result.message)
        }
      },
    })
  }, 1000),
}
var view = function(state, actions) {
  var diff = state.diff
  var second = diff % 60
  var minute = Math.floor(diff / 60 % 60)
  var hour = Math.floor(diff / 3600)
  var bomb = h('p', { class: 'bomb' },
    h('h2', null, '距離爆炸還有'),
    h('span', { class: 'hour' }, hour),
    h('span', { class: 'minute' }, minute),
    h('span', { class: 'second' }, second)
  )
  var safe = h('p', null,
    h('h2', null, '炸彈已解除！'),
    h('p', null, '新年快樂！')
  )
  var messages = h('div', { class: 'block-container' },
    h('div', null, '留言'),
    _.map(state.messages, function(message) {
      return h('div', { class: 'dialog' }, message )
    })
  )
  return(
    h('div', { class: 'container' },
      h('i', { class: 'fa fa-bomb fa-4x' }),
      (diff <= 0 && !safe) ? h('p', null,
        h('h2', null, '炸彈解除失敗！'),
        h('p', null, '新年快樂！')
      ) : state.safe ? safe : bomb,
      (!!state.sec || diff <= 0) ? h('div', { class: 'send-message' },
        h('input', { id: 'name-input', placeholder: '你的ＩＤ或名稱' }),
        h('br'),
        h('input', { id: 'message-input', placeholder: '留言內容' }),
        h('br'),
        h('button', { type: 'button', onclick: actions.sendMessage.bind(this, state.sec) }, '留言')
      ) : h('form', { class: 'guest-password', onsubmit: function(e) { e.preventDefault(); actions.guestPassword() } },
        h('input', { id: 'password-input', type: 'password', oninput: function() { app.setMessage('') } }),
        h('button', { type: 'submit' }, '猜密碼')
      ),
      h('div', null, state.message),
      !_.isEmpty(state.messages) && messages
    )
  )
}
var app = hyperapp.app(state, actions, view, root)
setInterval(app.countSecond, 1000)
