# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require './workers/workers'
require 'redis-namespace'
