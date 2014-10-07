ENV["REDISTOGO_URL"] ||= "redis://redistogo:f6a484c2e3c498ccdb4ed94357d89e6f@greeneye.redistogo.com:9548/"

uri = URI.parse(ENV["REDISTOGO_URL"])
Resque.redis = Redis.new(:host =&gt; uri.host, :port =&gt; uri.port, :password =&gt; uri.password)
