module ViewHelpers
  def js_url js
    "/js/#{js}?#{js_timestamp(js)}"
  end

  def js_tag js
    url = js_url js
    "<script type=\"text/javascript\" src=\"#{url}\"></script>"
  end

  def js_timestamp js
    path = "./public/js/#{js}"
    if File.exist? path
      File.mtime(path).to_i
    else
      Time.now.to_i
    end
  end

  def css_url css
    "/css/#{css}?#{css_timestamp(css)}"
  end

  def css_tag css
    url = css_url css
    title = css.split('.').first
    "<link rel=\"stylesheet\" type=\"text/css\" data-title=\"#{title}\" href=\"#{url}\">"
  end

  def css_timestamp css
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

  def hex_alpha hex, alpha
    t = '([0-9a-fA-F]{2})'
    r, g, b = /##{t}#{t}#{t}/.match(hex).to_a[1..3].map { |e| e.to_i(16) }
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end
end
