class ScraperWorker
	require "mechanize"
	require "json"
	require "pathname"
	attr_accessor :url, :output_filename
  @queue = :scraper_queue

	def initialize(url, name = nil, id = nil)

		@proxies = []

		@working_proxies = []

		@defective_proxies = []

		@current_proxy = {}

		@output_filename = name || DateTime.now.to_s

		@url = url

		@id = id
	end

	def self.perform(id)

		set_agent_with_proxy(get_random_proxy)
		@agent.get(URI(@url))
		page = @agent.page
		puts page.inspect
		status_code = page.code
		puts "Status: " + status_code.to_s

		puts @agent.page.class.name
		scrape_page
	end

	def run
		
		# load proxy list
		open_proxies_csv
		load_defective_list
		page = scrape_with_new_proxy(@url)
	end

	def open_proxies_csv
		puts "Opening proxies csv"

		Dir["proxy_lists/*.csv"].each do |csv_file_path|

  		puts csv_file_path
  		CSV.foreach(csv_file_path) do |row|
				puts row.inspect
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
	end

	def scrape_page
		begin
			url = URI(@agent.page.uri.to_s)
			current_page = @agent.page
			status_code = current_page.code
			puts "Scraping page: " + url.to_s

			links = current_page.search('.searchItem.title a')
			links.each do |link|
				puts "	Clicking link with text: " + link.inspect
				Mechanize::Page::Link.new(link, @agent, @agent.page).click

				# scrape individual report page
				scrape_report_page(@agent.page)
			end

			# keep record of this proxy working
			@working_proxies.push(@current_proxy)
			
			next_link = current_page.link_with(:text => "Next")
			next_link.click
			scrape_page unless next_link.nil?
		rescue Exception => e
			puts "Error scraping page: " + e.inspect + ", pushing this proxy to defective list.."
			puts "Attempting to rescrape page with new proxy ip for url: " + url.to_s
			push_to_defective @current_proxy
			scrape_with_new_proxy(url)

			#scrape_with_new_proxy(url, @working_proxies[Random.rand(@working_proxies.length)])
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

	def scrape_with_new_proxy(url, proxy = nil)
		begin

			puts "Queuing shit up"

			# add scraper class to resque queue
			Resque.enqueue(ScraperWorker, DateTime.now.to_s)
		rescue Exception => e
			puts "Unable to get to website with IP, trying again with other proxy.."
			puts e.to_s

			puts "Proxy with IP " + @current_proxy[:ip] + " defective, pushed to defective list."
			push_to_defective @current_proxy
			scrape_with_new_proxy(url)
		end
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

	def scrape_report_page(page)
		begin
			puts "Scraping report page"
			company = page.search('.companyBullet').text.gsub("\t","")
			address = page.search('.address').text.gsub("\t","").gsub("\n","")
			phone = page.search('.report-address table tr ul li:nth-child(1)').text.gsub("Phone:","").gsub("\t","")
			website = page.search('.report-address table tr ul li:nth-child(2) a').inner_text.gsub("Web:","").gsub("\t","")
			category = page.search('.report-address table tr ul li:nth-child(3)').text.gsub("Category:","").gsub("\t","")
			report_title = page.search('.reportTitle').text.gsub("\t","")
			report_content = page.search('.report-content').text.gsub("\n",'')
			unless phone == "" || phone.match(/^\s*$/i)
				puts "Company: " + company
				puts "Address: " + address
				puts "Website: " + website
				puts "Phone: " + phone
				puts "Report title: " + report_title
				puts "Report content: " + report_content
				write_to_csv([company, address, website, phone, report_title, report_content, category], @output_filename)
			else
				puts "Didn't find phone number... skipping"
			end
		rescue Exception => e
			puts "Error scraping report page: " + e.inspect
		end
	end
end