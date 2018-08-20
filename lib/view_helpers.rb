# frozen_string_literal: true

module ViewHelpers
  def js_url(js_name)
    "/js/#{js_name}?#{js_timestamp(js_name)}"
  end

  def js_tag(js_name)
    url = js_url js_name
    "<script type=\"text/javascript\" src=\"#{url}\"></script>"
  end

  def js_timestamp(js_name)
    path = "./public/js/#{js_name}"
    if File.exist? path
      File.mtime(path).to_i
    else
      Time.now.to_i
    end
  end

  def css_url(css)
    "/css/#{css}?#{css_timestamp(css)}"
  end

  def css_tag(css)
    url = css_url css
    title = css.split('.').first
    '<link rel="stylesheet" type="text/css" ' \
    "data-title=\"#{title}\" href=\"#{url}\">"
  end

  def css_timestamp(css)
    public_path = "./public/css/#{css}"
    views_path = "./views/css/#{css}.erb"
    if File.exist? public_path
      File.mtime(public_path).to_i
    elsif File.exist? views_path
      File.mtime(views_path).to_i
    else
      Time.now.to_i
    end
  end

  def hex_alpha(hex, alpha)
    t = '([0-9a-fA-F]{2})'
    r, g, b = /##{t}#{t}#{t}/.match(hex).to_a[1..3].map { |e| e.to_i(16) }
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end

  THEMES = %i[tawawa dark hatobatsugu].map(&:freeze).freeze
  DEFAULT_JS_LIST = %w[tawawa.js].freeze
  DEFAULT_CSS_LIST = %w[layout.css main.css television.css].freeze

  def get_css_list(tag)
    css_list = DEFAULT_CSS_LIST.dup
    css_list.push("#{tag}.css")
    css_list.push("#{curren_theme}.css") if curren_theme
    css_list
  end

  def view_erb(tag, opt = {})
    css_list = get_css_list tag
    js_list = DEFAULT_JS_LIST
    count = request.env['WsClientCount']
    bg = pick_background_img css_list
    locals = { css_list: css_list,
               js_list: js_list,
               ws_client_count: count,
               bg: bg }
    locals.merge!(opt[:locals]) unless opt[:locals].nil?
    erb(tag, locals: locals)
  end

  def pick_background_img(css_list)
    bg_dir = './public/bgs/*.png'
    if Time.now.monday? && curren_theme.nil?
      css_list.push 'tawawa.css'
      bg_dir = './public/bgs/tawawa/*.png'
    elsif curren_theme
      bg_dir = "./public/bgs/#{curren_theme}/*.png"
    elsif Random.rand * 256 > 255
      bg_dir = './public/bgs/koiking/*.png'
    end
    sample_background bg_dir
  end

  def sample_background(bg_dir)
    Dir.glob(bg_dir).map { |i| i.sub!('./public', '') }.sample
  end

  def curren_theme
    @curren_theme ||= THEMES.find { |theme| cookies[theme] }
  end
end
