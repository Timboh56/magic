require 'mechanize'
namespace :ripoff_report do 

	@proxies = [
		{ ip: "111.13.12.216", port: 80 },
	]

	task :run => :environment do
		run
	end

	def run
		open_proxies_csv
		root_url = "http://www.ripoffreport.com/c/56/outrageous-popular-rip-off/lawyers"
		page = scrape_with_new_proxy(root_url)
	end

	def scrape_page(page, url)
		begin
			puts "Scraping page: " + url.to_s
			status_code = page.code
			links = page.search('.searchItem.title a')
			links.each do |link|
				Mechanize::Page::Link.new(link, @agent, @agent.page).click
				scrape_report_page(@agent.page)
			end
			next_link = page.link_with(:text => "Next")
			next_link.click
			set_agent # use new proxy for next page
			scrape_page(page, page.uri.to_s) unless next_link.nil?
		rescue Exception => e
			puts "Error scraping page: " + e.inspect
			puts "Attempting to rescrape page with new proxy ip for url: " + url.to_s
			scrape_with_new_proxy(url)
		end
	end

	def scrape_with_new_proxy(url)
		begin
			set_agent
			@agent.get(URI(url))
			sleep(1)
			page = @agent.page
			puts page.inspect
			status_code = page.code
			puts "Status Code: " + status_code.to_s
			if status_code.match(/30[1|2]/)
				scrape_with_new_proxy(url)
			end
			scrape_page(page, url)
		rescue Exception => e
			puts "Unable to get to website with IP, trying again with other proxy.."
			puts e.to_s
			scrape_with_new_proxy(url)
		end
	end

	def set_agent
		@agent = Mechanize.new { |agent|
			agent.user_agent_alias = 'Mac Safari'
			agent.keep_alive = true
			agent.open_timeout = 5
			agent.read_timeout = 5
			agent.max_history = 1
			agent.redirect_ok = false
	  	agent.follow_meta_refresh = false
	  	agent.ignore_bad_chunking = true
	  	rand_no = Random.rand(@proxies.length)
			puts "Using proxy ip: " + @proxies[rand_no][:ip].to_s + ":" + @proxies[rand_no][:port].to_s
			agent.set_proxy @proxies[rand_no][:ip], @proxies[rand_no][:port]
		}
	end

	def scrape_report_page(page)
		begin
			puts "Scraping report page"
			company = page.search('.report-address table tr .companyBullet strong').text.gsub("\t","")
			address = page.search('.report-address table tr .address').text.gsub("\t","")
			phone = page.search('.report-address table tr ul li:nth-child(1)').text.gsub("Phone:","").gsub("\t","")
			website = page.search('.report-address table tr ul li:nth-child(3)').text.gsub("Web:","").gsub("\t","")

			unless company == "" && address == "" && phone == "" && website == ""
				puts "Company: " + company
				puts "Address: " + address
				puts "Website: " + website
				puts "Phone: " + phone
				write_to_csv([company, address, website, phone], "ripoff_lawyers")
			end
		rescue Exception => e
			puts "Error scraping report page: " + e.inspect
		end
	end

	def open_proxies_csv
		puts "Opening proxies csv"
		CSV.foreach("_reliable_list.csv") do |row|
			puts row.inspect
			ip = row[0].split(':')[0]
			port = row[0].split(':')[1]
			@proxies.push({ ip: ip, port: port })
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