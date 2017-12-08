require 'sidekiq'
require 'sidekiq/web'
require 'redis-namespace'
require './workers/workers'

$homu_redis = Redis::Namespace.new(:homu, redis: Redis.new)
