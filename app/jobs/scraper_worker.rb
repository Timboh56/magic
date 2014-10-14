class ScraperWorker
	require "mechanize"
	require "json"
	require "pathname"
	require "resque"
	attr_accessor :url, :output_filename
  @queue = :scraper_queue

  class << self
		def scrape_page
			begin
				page_uri = @agent.page.uri.to_s
				url = URI(page_uri)
				#unless ScrapedPage.where(url: page_uri).exists?
				#scraped_page = ScrapedPage.create!(url: page_uri)
				
				current_page = @agent.page
				puts "Scraping page: " + url.to_s

				set_agent_with_proxy

				# if root url has any parameters to scrape..
				scrape_sub_page(current_page, @scrape.root_data_set) if @scrape.root_data_set.present?

				@sub_pages.each do |sub_page|
					puts "Looking for link with selector: " + sub_page.link_selector.to_s + "..."

					# find links to pages to crawl on current page
					current_page.search(sub_page.link_selector).each do |link|
						puts "	Clicking link with text: " + link.inspect
						
						Mechanize::Page::Link.new(link, @agent, @agent.page).click

						# scrape individual page
						scrape_sub_page(@agent.page, sub_page)
					end
				end
				
				next_link = current_page.search(@next_link_selector).first

				Mechanize::Page::Link.new(next_link, @agent, @agent.page).click 

				scrape_page unless next_link.nil?
			rescue Exception => e
				puts "Error scraping page: " + e.inspect + ", deleting proxy.."
				puts "Attempting to rescrape page with new proxy ip for url: " + url.to_s

				push_to_defective @current_proxy
				enqueue(@agent.page.uri.to_s)
			end
		end

		def enqueue(url, proxy = nil)

			puts "Queuing shit up"

			# add scraper class to resque queue
			Resque.enqueue(ScraperWorker, @scrape.id, url)
		end

		def set_agent_with_proxy(proxy = nil)
			@agent = Mechanize.new { |agent|
				agent.user_agent_alias = 'Mac Safari'
				agent.keep_alive = false
				agent.open_timeout = 3
				agent.read_timeout = 3
				agent.max_history = 3

				puts "Setting Proxy"
				@current_proxy = proxy.nil? ? get_random_proxy : proxy
				puts @current_proxy.to_s
		  	puts "Using proxy ip: " + @current_proxy.ip.to_s + ":" + @current_proxy.port.to_s
				agent.set_proxy @current_proxy.ip, @current_proxy.port
			}
		end

		def get_random_proxy
			working_proxies = ProxyHost.where(:working => true)
			raise "There are no working proxies. " if working_proxies.count == 0
	  	rand_no = Random.rand(working_proxies.count)
	  	proxy = working_proxies[rand_no]
		end

		def scrape_sub_page(page, data_set)
			begin
				puts "Crawling page for data parameters"
				csv_row = []
				record_set = RecordSet.create!(data_set_id: data_set.id)
				data_set.parameters.each do |parameter|
					data = page.search(parameter.selector).text.gsub("\t","").gsub("\n","").gsub(parameter.text_to_remove, "")
					unless data == "" || data.match(/^\s*$/i)
						csv_row.push data
						params = { scrape_id: @scrape.id, record_set_id: record_set.id, parameter_id: parameter.id, text: data }
						Record.create!(params)
					else
						raise "Not all parameters found in page. Skipping.."
					end
				end
			rescue Exception => e
				puts "Error crawling page: " + e.inspect
				record_set.destroy!
			end
		end

		def push_to_defective proxy
			proxy.update_attributes!(:working => false)
		end

		def perform(id, root_url = nil)
			unless id.is_a? String
				scrape = Scrape.find(id["$oid"])
			else
				scrape = Scrape.find(id)
			end
			puts scrape.inspect

			@scrape = scrape

			@next_selector = scrape["next_selector"]

			@sub_pages = scrape.sub_pages_data_sets

			@proxies = []

			@current_proxy = {}

			@output_filename = scrape["filename"] || DateTime.now.to_s

			@url = root_url || scrape["URL"]

			@id = scrape["filename"] + DateTime.now.to_s

			begin
				puts "URL: " + @url.to_s

				set_agent_with_proxy
				@agent.get(URI(@url))
				page = @agent.page

				puts page.inspect
				puts @agent.page.class.name
				scrape_page

			rescue Exception => e
				puts e.inspect
		    login_page = exception.page
 				puts "Unable to get to website with IP, trying again with other proxy.."
				puts "Proxy with IP " + @current_proxy.ip + " defective, deleting poxy.."
				push_to_defective @current_proxy
				enqueue(@url)
			end
		end
	end
end