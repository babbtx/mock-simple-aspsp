# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

env  = ENV['RACK_ENV'] || 'development'
port = ENV['PORT']     || 3000

rackup      DefaultRackup
port        port
environment env

cert_file = File.expand_path(File.join(File.dirname(__FILE__), '../ssl.crt'))
key_file = File.expand_path(File.join(File.dirname(__FILE__), '../ssl.key'))
if env == 'development' && File.exists?(cert_file) && File.exists?(key_file)
  ssl_bind('0.0.0.0', (port + 1),
           cert: cert_file,
           key: key_file,
           verify_mode: 'none')
end

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
