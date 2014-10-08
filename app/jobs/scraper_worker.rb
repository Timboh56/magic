class ScraperWorker
	require "mechanize"
	require "json"
	require "pathname"
	require "resque"
	attr_accessor :url, :output_filename
  @queue = :scraper_queue

  class << self
		def open_proxies_csv
			puts "Opening proxies csv"

			Dir["proxy_lists/*.csv"].each do |csv_file_path|

	  		puts csv_file_path
	  		CSV.foreach(csv_file_path) do |row|
					ip = row[0].split(':')[0]
					port = row[0].split(':')[1]
					@proxies.push({ ip: ip, port: port })
				end
	  	end

			puts "Done with proxies csv."
		end

		def write_to_csv(row, filename = nil)
			filename = filename || @output_filename.to_s
			puts "Writing " + row.inspect + " to csv file " + filename.to_s
			CSV.open("csvs/" + filename + ".csv", "ab") do |csv|
			  csv << row
			end

			# save scrape object
			@scrape.records_collected += 1
			@scrape.save!
		end

		def scrape_page
			begin
				url = URI(@agent.page.uri.to_s)
				current_page = @agent.page
				status_code = current_page.code
				puts "Scraping page: " + url.to_s

				@links.each do |crawl_link|
					puts "Looking for link with selector: " + crawl_link.link_selector.to_s + "..."

					# find links to pages to crawl on current page
					current_page.search(crawl_link.link_selector).each do |link|
						
						puts "	Clicking link with text: " + link.inspect
						
						Mechanize::Page::Link.new(link, @agent, @agent.page).click

						# scrape individual report page
						scrape_report_page(@agent.page, crawl_link)
					end
				end
				
				next_link = current_page.link_with(:text => @next_text)
				next_link.click
				scrape_page unless next_link.nil?
			rescue Exception => e
				puts "Error scraping page: " + e.inspect + ", pushing this proxy to defective list.."
				puts "Attempting to rescrape page with new proxy ip for url: " + url.to_s

				push_to_defective @current_proxy
				enqueue(url)
			end
		end

		def load_defective_list 
			CSV.open("csvs/defective_list.csv").each do |row|
				ip = row[0].split(':')[0]
				port = row[0].split(':')[1]
				@defective_proxies.push({ ip: ip, port: port })
			end
		end

		def push_to_defective proxy
			@defective_proxies.push proxy
			write_to_csv([proxy[:ip]], "defective_list")
		end

		def enqueue(url, proxy = nil)

			puts "Queuing shit up"

			# add scraper class to resque queue
			Resque.enqueue(ScraperWorker, @scrape.id)
		end

		def set_agent_with_proxy(proxy = nil)
			@agent = Mechanize.new { |agent|
				agent.user_agent_alias = 'Mac Safari'
				agent.keep_alive = true
				agent.open_timeout = 2
				agent.read_timeout = 2
				agent.max_history = 2
				puts "Setting Proxy"
				@current_proxy = proxy.nil? ? get_random_proxy : proxy
				puts @current_proxy.to_s
		  	puts "Using proxy ip: " + @current_proxy[:ip].to_s + ":" + @current_proxy[:port].to_s
				agent.set_proxy @current_proxy[:ip], @current_proxy[:port]
			}
		end

		def get_random_proxy
	  	rand_no = Random.rand(@proxies.length)
	  	proxy = @proxies[rand_no]
	  	get_random_proxy if @defective_proxies.include? proxy
			proxy
		end

		def scrape_report_page(page, link)
			begin
				puts "Crawling page for data parameters"
				csv_row = []
				link.parameters.each do |parameter|
					data = page.search(parameter.selector).text.gsub("\t","").gsub("\n","").gsub(parameter.text_to_remove, "")
					unless data == "" || data.match(/^\s*$/i)
						csv_row.push data
					else
						puts "Didn't find any data for " + link.name.to_s + " on this page.. skipping"
					end
				end
				write_to_csv(csv_row, @output_filename)

			rescue Exception => e
				puts "Error crawling page: " + e.inspect
			end
		end

		def perform(id)
			unless id.is_a? String
				scrape = Scrape.find(id["$oid"])
			else
				scrape = Scrape.find(id)
			end
			puts scrape.inspect

			@scrape = scrape

			@next_selector = scrape["next_selector"]

			@links = scrape.links

			@proxies = []

			@defective_proxies = []

			@current_proxy = {}

			@output_filename = scrape["filename"] || DateTime.now.to_s

			@url = scrape["URL"]

			@id = scrape["filename"] + DateTime.now.to_s

			begin

				# load proxy list
				open_proxies_csv
				load_defective_list

				set_agent_with_proxy
				@agent.get(URI(@url))
				page = @agent.page

				puts page.inspect
				puts @agent.page.class.name
				scrape_page

			rescue Exception => e
				puts "Unable to get to website with IP, trying again with other proxy.."
				puts e.to_s

				puts "Proxy with IP " + @current_proxy[:ip] + " defective, pushed to defective list."
				push_to_defective @current_proxy
				enqueue(@url)
			end
		end
	end
end