require 'resque/tasks'
require 'resque_scheduler'
require 'resque/scheduler/server'
require 'resque/scheduler/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
  require 'resque'
  require 'resque-scheduler'

  # you probably already have this somewhere
  Resque.redis = 'localhost:6379'

  Resque.schedule = YAML.load_file('resque_scheduler.yml')

end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"