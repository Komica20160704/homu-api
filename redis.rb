require 'redis-namespace'
$homu_redis = Redis::Namespace.new(:homu, redis: Redis.new)
