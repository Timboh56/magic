module RetriedJob
  def on_failure_retry(e, *args)
  	p "Worker failed: #{ e.inspect }"
    Resque.enqueue self, *args
  end
end
