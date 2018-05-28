# frozen_string_literal: true

module AppHelpers
  def production?
    settings.env == 'production'
  end

  def vue_js_url
    @vue_js_url ||= begin
      return 'vue.min.js' if production?
      'vue.js'
    end
  end
end
