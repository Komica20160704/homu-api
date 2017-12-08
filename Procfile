web: bundle exec thin start -p $PORT
worker: bundle exec sidekiq -r ./workers/workers.rb -C ./config/sidekiq.yml
