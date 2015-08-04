#!/usr/bin/env puma

directory '/home/deploy/SpartaHackII-Web/current'
rackup "/home/deploy/SpartaHackII-Web/current/config.ru"
environment 'production'

pidfile "/home/deploy/SpartaHackII-Web/shared/tmp/pids/puma.pid"
state_path "/home/deploy/SpartaHackII-Web/shared/tmp/pids/puma.state"
stdout_redirect '/home/deploy/SpartaHackII-Web/current/log/puma.error.log', '/home/deploy/SpartaHackII-Web/current/log/puma.access.log', true


threads 4,16

bind 'unix:///home/deploy/SpartaHackII-Web/shared/tmp/sockets/SpartaHackII-Web-puma.sock'

workers 0



preload_app!


on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = "/home/deploy/SpartaHackII-Web/current/Gemfile"
end


on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

