new Vue({
  el: '#search',
  data: {
    loading: false,
    prevQuery: null,
    query: '',
    blockType: 'full',
    blocks: [],
  },
  mounted: function() {
    window.onpopstate = this.reSearchAjax
    this.reSearchAjax()
  },
  methods: {
    search: function(event) {
      event.preventDefault()
      if (!this.query || this.query == this.prevQuery) {
        return
      }
      var data = { id: this.query }
      var replaceUrl = '/search?' + $.param(data)
      window.history.pushState(data, document.title, replaceUrl)
      this.searchAjax()
    },
    beforeSearch: function() {
      this.loading = true
    },
    searchSuccess: function(response) {
      var data = response.data
      this.blocks = data.map(this.transferBlock)
    },
    afterSearch: function() {
      this.loading = false
      this.prevQuery = this.query
    },
    searchAjax: function() {
      this.beforeSearch()
      axios.get(document.getElementById('homu-api-link').href + 'posts?id=' + this.query)
        .then(this.searchSuccess)
        .then(this.afterSearch)
    },
    reSearchAjax: function() {
      var url = new URL(location)
      var query = url.searchParams.get('id')
      if (query && this.query != query) {
        this.query = query
        this.searchAjax()
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
  },
})
