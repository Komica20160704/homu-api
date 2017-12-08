require 'json'
unless ENV['RACK_ENV'] == 'production'
  heroku_config = JSON.parse(`heroku config --json`)
  heroku_config.each do |key, value|
    next if key == 'RACK_ENV'
    ENV[key] = value
  end
end
