# config.ru
require './app'
require './middlewares/homu_checker'
require './middlewares/homu_notifier'

Faye::WebSocket.load_adapter('thin') if $0.match /thin$/

$stdout.sync = true

use HomuApi::HomuChecker
use HomuApi::HomuNotifier
run HomuApi::App.new
