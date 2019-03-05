new Vue({
  el: '#search',
  data: {
    loading: false,
    prevQuery: null,
    prevKey: null,
    prevPage: null,
    key: 'id',
    query: '',
    blockType: 'full',
    blocks: [],
    token: null,
    payload: {},
    totalPages: 0,
    currentPage: 1,
  },
  methods: {
    searchBy: function(event) {
      var key = event.currentTarget.dataset.key || 'id'
      this.key = key
      this.currentPage = 1
    },
    search: function(event) {
      if (
        !this.query ||
        (
          this.query == this.prevQuery &&
          this.key == this.prevKey &&
          this.currentPage == this.prevPage
        )
      ) {
        return
      }
      var key = !!this.token ? this.key : 'id'
      var data = { [key]: this.query, page: this.currentPage }
      var replaceUrl = '/search?' + $.param(data)
      window.history.pushState(
        { key: key, query: this.query, page: this.currentPage },
        document.title,
        replaceUrl,
      )
      this.searchAjax(data)
    },
    advSearch: function(event) {
      if (!this.token) {
        window.openJaparimanSabisuWindow()
      }
    },
    prevsPage: function(event) {
      this.currentPage -= 1
      this.search()
    },
    nextPage: function(event) {
      this.currentPage += 1
      this.search()
    },
    changePage: function(page) {
      this.currentPage = page
      this.search()
    },
    beforeSearch: function() {
      this.loading = true
    },
    searchSuccess: function(response) {
      var data = response.data
      var headers = response.headers
      this.totalPages = parseInt(headers['total-pages']) || 0
      this.blocks = data.map(this.transferBlock)
    },
    afterSearch: function() {
      this.loading = false
      this.prevQuery = this.query
      this.prevKey = this.key
      this.prevPage = this.currentPage
    },
    searchError: function(error) {
      if (error.response && error.response.status === 401) {
        this.token = null
        this.loading = false
        localStorage.removeItem('token')
      }
    },
    searchAjax: function(data) {
      this.beforeSearch()
      var homuApiUrl = document.getElementById('homu-api-link').href + 'posts'
      var config = {
        params: data,
        headers: {},
      }
      if (this.token) {
        config.headers['Authorization'] = 'Bearer ' + this.token
      }
      axios.get(homuApiUrl, config)
        .then(this.searchSuccess)
        .then(this.afterSearch)
        .catch(this.searchError)
    },
    reSearchAjax: function(event) {
      var query = event.state.query
      var key = event.state.key
      var page = event.state.page
      if (query && (
        this.query != query ||
        this.key != key ||
        this.currentPage != page)
      ) {
        this.query = query
        this.key = key
        this.page = page
        this.searchAjax({ [key]: query })
      }
    },
    transferBlock: function(block) {
      block.postAt = block.post_at
      block.headNumber = block.head_number
      block.hiddenBodyCount = block.hidden_body_count
      delete block.post_at
      delete block.head_number
      delete block.hidden_body_count
      return block
    },
    receiveMessage: function(event) {
      var homuApiUrl = document.getElementById('homu-api-link').href
      if (event.origin + '/' !== homuApiUrl) {
        return
      } else if (event.data.type === 'japariman:sabisu') {
        localStorage.setItem('token', event.data.token)
        this.token = event.data.token
        this.payload = event.data.payload
      }
    }
  },
  mounted: function() {
    this.$el.style.display = null
    window.onpopstate = this.reSearchAjax
    this.token = localStorage.getItem('token')
    if (!history.state) {
      var url = new URL(location)
      var query = url.searchParams.get('id')
      history.replaceState(
        { key: 'id', query: query, page: 1 },
        document.title,
      )
    }
    this.reSearchAjax(history)
  },
  created () {
    window.addEventListener('message', this.receiveMessage)
  },
  destroyed () {
    this.$el.style.display = 'none'
    window.removeEventListener('message', this.receiveMessage)
  }
})

function PopupCenter(url, title, w, h) {
  var dualScreenLeft = window.screenLeft != undefined ? window.screenLeft : window.screenX
  var dualScreenTop = window.screenTop != undefined ? window.screenTop : window.screenY
  var width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width
  var height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height
  var left = ((width / 2) - (w / 2)) + dualScreenLeft
  var top = ((height / 2) - (h / 2)) + dualScreenTop
  var newWindow = window.open(url, title, 'scrollbars=yes, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left)
  if (window.focus) {
    newWindow.focus()
  }
  return newWindow
}

function openJaparimanSabisuWindow() {
  PopupCenter(
    japariman + token,
    'japariman',
    480,
    600,
  )
}
