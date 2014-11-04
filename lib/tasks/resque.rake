require 'resque/tasks'
require 'resque_scheduler'
require 'resque_scheduler/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
  require 'resque'
  require 'resque_scheduler'
  require 'resque/scheduler'

  Resque.schedule = YAML.load_file('config/resque_scheduler.yml')

end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"