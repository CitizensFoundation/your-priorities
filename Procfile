web: bundle exec passenger start -p $PORT --max-pool-size 1 
worker: bundle exec sidekiq -e production -C config/sidekiq.yml
