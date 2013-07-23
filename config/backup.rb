require 'yaml'
db_conf = YAML.load_file(File.expand_path('../../config/database.yml',  __FILE__))
rails_env = ENV['RAILS_ENV'] || 'development'

Backup::Database::MySQL.defaults do |db|
  db.name     = db_conf[rails_env]["database"]
  db.username = db_conf[rails_env]["username"]
  db.password = db_conf[rails_env]["password"]
  db.host     = db_conf[rails_env]["host"]
  db.port     = db_conf[rails_env]["port"]
end

Backup::Compressor::Gzip.defaults do |compressor|
  compressor.level = 9
end

Backup::Storage::Local.defaults do |storage|
  storage.path = "~/sites/social_innovation_internal/shared/backups/"
end

Backup::Model.new(:hourly_backup, 'Backup the database') do
  split_into_chunks_of 250
  database MySQL
  compress_with Gzip
  store_with Local do |storage|
    storage.keep = 96
  end
end

Backup::Model.new(:daily_backup, 'Backup the database') do
  split_into_chunks_of 250
  database MySQL
  compress_with Gzip
  store_with Local do |storage|
    storage.keep = 21
  end
end

Backup::Model.new(:weekly_backup, 'Backup the database') do
  split_into_chunks_of 250
  database MySQL
  compress_with Gzip
  store_with Local do |storage|
    storage.keep = 12
  end
end

Backup::Model.new(:monthly_backup, 'Backup the database') do
  split_into_chunks_of 250
  database MySQL
  compress_with Gzip
  store_with Local do |storage|
    storage.keep = 12
  end
end
