require "resque_scheduler"
ENV["REDISTOGO_URL"] ||= "redis://redistogo:f6a484c2e3c498ccdb4ed94357d89e6f@greeneye.redistogo.com:9548/"

uri = URI.parse(ENV["REDISTOGO_URL"])
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }

# The schedule doesn't need to be stored in a YAML, it just needs to
# be a hash.  YAML is usually the easiest.
Resque.schedule = YAML.load_file(Rails.root.join('config', 'resque_scheduler.yml'))