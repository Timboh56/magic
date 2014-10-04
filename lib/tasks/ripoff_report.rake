require "mechanize"
require "json"
require "pathname"

namespace :ripoff_report do 

	@proxies = [
		{ ip: "111.13.12.216", port: 80 },
		{ ip: "220.181.32.106", port: 80 },
		{ ip: "218.203.13.180", port: 80 },
		{ ip: "148.251.234.73", port: 80 },
		{ ip: "150.145.95.205", port: 80 },
		{ ip: "64.107.13.126", port: 80 },
		{ ip: "149.255.255.250", port: 80 },
		{ ip: "120.202.249.230", port: 80 },
		{ ip: "23.251.149.27", port: 80 },
		{ ip: "123.155.243.140", port: 80 },
		{ ip: "218.203.13.177", port: 80 },
		{ ip: "94.201.134.251", port: 80 },
		{ ip: "94.198.135.79", port: 80 },
		{ ip: "211.143.146.239", port: 80 },
		{ ip: "196.201.217.48", port: 80 },
		{ ip: "122.96.59.103", port: 80 },
		{ ip: "218.108.170.171", port: 80 },
		{ ip: "218.108.168.68", port: 80 },
		{ ip: "110.170.137.254", port: 8080 },
		{ ip: "137.135.166.225", port: 8123 },
		{ ip: "218.203.13.180", port: 80 },
		{ ip: "217.174.254.186", port: 8080 }
	]

	@root_urls = [
		"http://www.ripoffreport.com/c/126/health-fitness/plastic-surgeons",
		"http://www.ripoffreport.com/c/381/health-fitness/dental-services",
	]

	@working_proxies = []

	@defective_proxies = []

	@current_proxy = {}

	@output_file_name = "ripoff_doctors"

	task :run => :environment do
		run
	end

	def run
		open_proxies_csv
		#root_url = "http://www.ripoffreport.com/c/56/outrageous-popular-rip-off/lawyers?pg=68"
		#root_url = "http://www.ripoffreport.com/c/496/community/attorneys-general"
		#root_url = "http://www.ripoffreport.com/c/381/health-fitness/dental-services?pg=44"
		root_url = "http://www.ripoffreport.com/c/559/health-fitness/doctors?pg=68"
		page = scrape_with_new_proxy(root_url)
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
			puts "Error scraping page: " + e.inspect
			puts "Attempting to rescrape page with new proxy ip for url: " + url.to_s
			scrape_with_new_proxy(url)

			#scrape_with_new_proxy(url, @working_proxies[Random.rand(@working_proxies.length)])

		end
	end

	def scrape_with_new_proxy(url, proxy = nil)
		begin
			set_agent_with_proxy(proxy)
			@agent.get(URI(url))
			page = @agent.page
			puts page.inspect
			status_code = page.code
			puts "Status: " + status_code.to_s

			puts @agent.page.class.name
			scrape_page
		rescue Exception => e
			puts "Unable to get to website with IP, trying again with other proxy.."
			puts e.to_s

			puts "Proxy with IP " + @current_proxy[:ip] + " defective, pushed to defective list."
			@defective_proxies.push(@current_proxy)
			scrape_with_new_proxy(url)
		end
	end

	def set_agent_with_proxy(proxy = nil)
		@agent = Mechanize.new { |agent|
			agent.user_agent_alias = 'Mac Safari'
			agent.keep_alive = true
			agent.open_timeout = 3
			agent.read_timeout = 3
			agent.max_history = 2

			@current_proxy = proxy.nil? ? get_random_proxy : proxy
	
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
			address = page.search('.address').text.gsub("\t","")
			phone = page.search('.report-address table tr ul li:nth-child(1)').text.gsub("Phone:","").gsub("\t","")
			website = page.search('.report-address table tr ul li:nth-child(2) a').inner_text.gsub("Web:","").gsub("\t","")
			category = page.search('.report-address table tr ul li:nth-child(3)').text.gsub("Category:","").gsub("\t","")
			report_title = page.search('.reportTitle').text.gsub("\t","")
			report_content = page.search('.report-content').text
			unless phone == ""
				puts "Company: " + company
				puts "Address: " + address
				puts "Website: " + website
				puts "Phone: " + phone
				puts "Report title: " + report_title
				puts "Report content: " + report_content
				write_to_csv([company, address, website, phone, report_title, report_content, category], @output_file_name)
			else
				puts "Didn't find phone number... skipping"
			end
		rescue Exception => e
			puts "Error scraping report page: " + e.inspect
		end
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

	def write_to_csv(row, name)
		puts "Writing " + row.inspect + " to csv file " + name.to_s
		CSV.open(name.to_s + ".csv", "ab") do |csv|
		  csv << row
		end
	end
end