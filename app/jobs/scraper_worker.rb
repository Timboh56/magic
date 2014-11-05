class ScraperWorker
  require "mechanize"
  require "pathname"
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

            # convert node to uri string
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
      
      if @scrape.pagination_type === "PageLink"
        next_link = node_to_uri(current_page.search(@scrape.next_selector).last) rescue nil
      else
        
        @page_index += 1

        if @scrape.url_parameterization_type === "Integer"
          
          # use URL parameters to find next
          url_param = (@scrape.page_interval * @page_index).to_s
        
        else

          # use next record in record list for parameter in URL
          url_param = (@scrape.parameterized_record_list.records[@page_index].text) rescue nil
        
        end

        p url_param.inspect

        next_link = url_param ? @scrape.page_parameterized_url.gsub(":page", url_param) : nil

      end

      unless next_link.nil?

        @agent.get(next_link)

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

        # create a record set if a data set exists
        record_set = data_set ? RecordSet.create!(data_set_id: data_set.id, scrape_id: @scrape.id) : nil

        data_set.parameters.each do |parameter|
          data = page.search(parameter.selector).text.gsub("\t","").gsub("\n","").gsub(parameter.text_to_remove, "")
          unless data == "" || data.match(/^\s*$/i)
            csv_row.push data

            record_params = {
              record_type: parameter.name,
              record_list_id: @scrape.scraped_record_list.id,
              parameter_id: parameter.id,
              text: data
            }

            unless Record.where(record_params).exists?
              record = Record.create!(record_params.merge!({ record_set_id: (record_set ? record_set.id : nil) }))
              puts "Whoop Whoop! Record added: " + record_params.inspect
            end
          else
            raise "Not all parameters found in page. Skipping.."
          end
        end

        # sleep for random 5 seconds
        sleep(rand(5))
        
      rescue Exception => e
        puts "Error crawling page: " + e.inspect
        record_set.destroy!
      end
    end

    def push_to_defective proxy
      proxy.update_attributes!(:working => false)
    end

    def perform(id, continue = false, root_url = nil)
      p id.inspect
      @scrape = Scrape.find(id)
      @scrape.status = "Running.."
      @scrape.save!
      
      @sub_pages = @scrape.sub_pages_data_sets

      @proxies = []

      @current_proxy = {}

      @output_filename = @scrape["filename"] || DateTime.now.to_s

      @url = continue == true ? @scrape.last_scanned_url : (root_url || @scrape["URL"])

      @website_root = @url.match(/^((http|https):\/.+(\.(com|net|org|gov|it|biz)))/)[1]

      @id = @scrape["filename"] + DateTime.now.to_s

      # if using parameters
      @page_index = 0

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
      p e.inspect
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