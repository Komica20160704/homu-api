# config.ru
require './heroku_config'
require './sidekiq'
require './app'
require './middlewares/homu_checker'
require './middlewares/homu_notifier'

Faye::WebSocket.load_adapter('thin') if $0.match /thin$/

$stdout.sync = true
$stderr.sync = true

use HomuApi::HomuChecker
use HomuApi::HomuNotifier
run Rack::URLMap.new('/' => HomuApi::App.new, '/sidekiq' => Sidekiq::Web)
