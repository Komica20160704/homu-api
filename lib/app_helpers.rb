# frozen_string_literal: true

module AppHelpers
  def production?
    settings.env == 'production'
  end

  def token
    md5 = Digest::MD5.new
    secret = ENV['SECRET'].to_s
    today = Time.now.strftime '%Y/%m/%d'
    ip = request.ip.to_s
    md5 << secret << today << ip
    md5.hexdigest[9..16]
  end

  def homu_url
    return 'https://www.homu-api.com' if production?
    'https://homu-api.dev'
  end

  def homu_api_url
    return 'https://homu.homu-api.com' if production?
    'https://api-homu.dev'
  end

  def japariman_url
    'https://japariman.homu-api.com/'
  end

  def vue_js_url
    @vue_js_url ||= begin
      return 'vue.min.js' if production?
      'vue.js'
    end
  end
end
