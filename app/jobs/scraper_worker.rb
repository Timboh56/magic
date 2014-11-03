class ScraperWorker
  require "mechanize"
  require "json"
  require "pathname"
  require "resque"
  require "resque/errors"
  attr_accessor :url, :output_filename
  @queue = :scraper_queue

  class << self
    def scrape_page
      page_uri = @agent.page.uri.to_s
      url = URI(page_uri)
      current_page = @agent.page
      puts "Scraping page: " + url.to_s

      set_agent_with_proxy

      save_last_url(url)

      # if root url has any parameters to scrape..
      scrape_sub_page(current_page, @scrape.root_data_set) if @scrape.root_data_set.present?

      @sub_pages.each do |sub_page|
        puts "Looking for link with selector: " + sub_page.link_selector.to_s + "..."

        # find links to pages to crawl on current page
        current_page.search(sub_page.link_selector.to_s).each do |link|
          begin
            link_url = node_to_uri(link)

            puts "  Clicking link with text: " + link_url

            @agent.get(link_url)

            # scrape individual page
            scrape_sub_page(@agent.page, sub_page)
          rescue Exception => e
            puts "Unable to get page " + link_url + ": " + e.inspect
            puts "Skipping"
          end
        end
      end
      
      if @next_selector.present?
        next_link = current_page.search(@next_selector).last
        @agent.get(node_to_uri(next_link)) 

      else

        @page_index += 1

        # use URL parameters to find next
        next_link = @scrape.page_parameterized_url.gsub(":page", (@page_interval * @page_index).to_s)

        @agent.get(next_link)
      end

      unless next_link.nil?
        puts "Clicked next link: " + next_link.to_s
        scrape_page
      else
        puts "------------------- END ----------------"
      end
    end

    def enqueue(url)

      puts "Queuing shit up with url: " + url.inspect

      # add scraper class to resque queue
      Resque.enqueue(ScraperWorker, @scrape.id, url)
    end

    def set_agent_with_proxy(proxy = nil)
      @agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
        agent.keep_alive = true
        agent.open_timeout = 3
        agent.read_timeout = 3
        agent.max_history = 3

        if @scrape.use_proxies
          puts "Setting Proxy"
          @current_proxy = proxy.nil? ? get_random_proxy : proxy
          puts @current_proxy.to_s
          puts "Using proxy ip: " + @current_proxy.ip.to_s + ":" + @current_proxy.port.to_s
          agent.set_proxy @current_proxy.ip, @current_proxy.port
        end
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
        record_set = RecordSet.create!(data_set_id: data_set.id, scrape_id: @scrape.id)
        data_set.parameters.each do |parameter|
          data = page.search(parameter.selector).text.gsub("\t","").gsub("\n","").gsub(parameter.text_to_remove, "")
          unless data == "" || data.match(/^\s*$/i)
            csv_row.push data
            params = { scrape_id: @scrape.id, parameter_id: parameter.id, text: data }
            unless Record.where(params).exists?
              record = Record.create!(params.merge!({ record_set_id: record_set.id}))
              puts "Whoop Whoop! Record added: " + params.inspect
            end
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

    def perform(id, continue = false, root_url = nil)
      unless id.is_a? String
        scrape = Scrape.find(id["$oid"])
      else
        scrape = Scrape.find(id)
      end

      begin

        @scrape = scrape

        @scrape.status = "Running.."

        @scrape.save!
        
        @next_selector = scrape.next_selector

        @sub_pages = scrape.sub_pages_data_sets

        @proxies = []

        @current_proxy = {}

        @output_filename = scrape["filename"] || DateTime.now.to_s

        @url = continue == true ? @scrape.last_scanned_url : (root_url || scrape["URL"])

        @website_root = @url.match(/^((http|https):\/.+(\.(com|net|org|gov|it|biz)))/)[1]

        @id = scrape["filename"] + DateTime.now.to_s

        # if using parameters
        @page_index = 0

        @page_interval = scrape.page_interval

        puts "URL: " + @url.to_s

        set_agent_with_proxy
        @agent.get(URI(@url))
        page = @agent.page
        scrape_page

      rescue Timeout::Error, Mechanize::ResponseCodeError
        if @scrape.use_proxies
          puts "Unable to get to website with IP, trying again with other proxy.."
          puts "Proxy with IP " + @current_proxy.ip + " defective, deleting poxy.."
          push_to_defective @current_proxy
        end
        save_last_url(@url)
      rescue Resque::TermException
        Resque.enqueue(self, key)
      rescue Exception => e
        puts e.inspect
        @scrape.status = "Error"
        @scrape.save!
      end
    end

    def node_to_uri node
      uri = URI(node.attributes['href'].value.to_s).to_s
      if uri.match(/^(http|https):\/.+(\.(com|net|org|gov|it|biz))/).nil?
        @website_root + uri
      else
        uri
      end
    end

    def save_last_url(url = nil)
      @scrape.last_scanned_url = url || @agent.page.uri.to_s
      @scrape.save!
    end
  end
end