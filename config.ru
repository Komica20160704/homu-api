# config.ru
require './app'
require './middlewares/homu_checker'
require './middlewares/web_socket_backend'

Faye::WebSocket.load_adapter('thin') if $0.match /thin$/

use HomuApi::HomuChecker
use HomuApi::WebSocketBackend
run HomuApi::App.new
