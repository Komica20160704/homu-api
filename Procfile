web: bundle exec thin start -p $PORT
worker: bundle exec sidekiq -r ./sidekiq.rb -C ./config/sidekiq.yml
#
