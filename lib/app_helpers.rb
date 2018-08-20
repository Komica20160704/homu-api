# frozen_string_literal: true

module AppHelpers
  def production?
    settings.env == 'production'
  end

  def homu_url
    return 'https://www.homu-api.com' if production?
    'https://homu-api.dev'
  end

  def homu_api_url
    return 'https://homu.homu-api.com' if production?
    'https://api-homu.dev'
  end

  def vue_js_url
    @vue_js_url ||= begin
      return 'vue.min.js' if production?
      'vue.js'
    end
  end
end
