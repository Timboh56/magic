# encoding: utf-8

class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps
  require "mechanize"
  require "pathname"
  field :url, :type => String
  field :page_parameterized_url, :type => String
  field :pagination_type, :type => String, :default => "PageLink" # "PageLink" or "URL"
  field :url_parameterization_type, :type => String # "Data" or "Integer"
  field :page_interval, :type => Integer
  field :filename, :type => String
  field :next_selector, :type => String
  field :use_proxies, :type => Boolean, :default => false
  field :last_scanned_url, :type => String
  field :status, :type => String
  field :parameterized_textarea, :type => String # if using textarea for list of url params to scrape
  has_many :data_sets

  # record set is a "row" of data, scraped from individual page
  has_many :record_sets

  # record list of previously scraped records for use as URL parameters. 
  belongs_to :parameterized_record_list, class_name: "RecordList", autosave: true, inverse_of: :scrapers_used_by
  
  # record list of records created by scrape
  has_one :scraped_record_list, class_name: "RecordList", autosave: true, inverse_of: :created_in_scraper, dependent: :destroy
  
  accepts_nested_attributes_for :data_sets, allow_destroy: true
  before_create :generate_record_list

  def self.generate_craigslist_scrape(post_ids)
    cl_scrape = create!(
      url: "http://losangeles.craigslist.org/reply/lax/pho/",
      url_parameterization_type: "Data",
      use_proxies: true,
      parameterized_textarea: post_ids.join("\n")
    )
  end

  def records_count
    scraped_record_list.records_count rescue 0
  end

  def root_data_set
    data_sets.select { |d| !d.link_selector.present? }.first
  end

  def sub_pages_data_sets
    data_sets.select { |d| d.link_selector.present? }
  end


  def run
    puts id.inspect
    Resque.enqueue(ScraperWorker, id.to_s, last_scanned_url.present?)
  end

  def restart
    record_sets.destroy_all
    Resque.enqueue(ScraperWorker, id.to_s)
  end

  def get_csv_data_row record_set
    record_set.records.map { |r| r.text }
  end

  def get_csv_header_row parameters
    csv_row = []
    parameters.each do |parameter|
      csv_row.push parameter.name
    end
    csv_row
  end

  def format_to_downloadable_csv

    CSV.generate do |csv|
      data_sets.each do |data_set|

        # header
        csv << get_csv_header_row(data_set.parameters)

        # data
        data_set.record_sets.order("created_at ASC").each do |record_set|
          csv << get_csv_data_row(record_set)
        end
      end
    end
  end

  def init(continue, root_url = nil)
    @proxies = []

    @current_proxy = {}

    @output_filename = filename || DateTime.now.to_s

    starting_url = continue == true ? last_scanned_url : root_url || url

    @website_root = starting_url.match(/^((http|https):\/.+(\.(com|net|org|gov|it|biz)))/)[1]

    # if using parameters
    @page_index = 0

    puts "URL: " + starting_url.to_s

    scrape_page(starting_url)
  end


  def email_cl_emails(cl_emails, message, limit = nil, username = nil, pass = nil)
    dummies = Email.dummies
    count = dummies.count
    limit ||= 50
    cl_emails.take(limit).each_with_index do |cl_email, i|
      begin
        username ||= dummies[i % count].email
        pass ||= dummies[i % count].password
        GmailSender::send_email(username, pass, cl_email, message, "Saw your ad") if cl_email.present?
        p "Success!"
      rescue Exception => e
        p "ERROR: " + e.inspect
      end
    end
  end

  def scrape_cl(ids = nil, partial_url = "http://losangeles.craigslist.org/reply/lax/pho/", limit = nil)
    a = Mechanize.new
    ids ||= parameterized_textarea.split("\n")
    emails = []
    phones = []
    limit ||= 50
    count = ProxyHost.all.count
    ids.take(limit).each_with_index do |cl_id, index|
      begin
        selected_proxy = ProxyHost.all[index % count]
        a.set_proxy selected_proxy.ip, selected_proxy.port
        page = a.get(partial_url + cl_id)
        page_text = page.search("ul").text
        phone_number = page_text.match(/(☎\s*\d{10})/m)[0] rescue nil
        email = page_text.match(/(\S{5}-\d{10}@sale.craigslist.org)/)[0] rescue nil
        p cl_id.inspect
        p phone_number.inspect
        p email.inspect
        emails << email if email
        phones << phone_number if phone_number
        sleep(rand(10))
      rescue Mechanize::ResponseCodeError => e
        p e.inspect
      rescue Exception::NoMethodError => e
        p e.inspect
      rescue Net::HTTP::Persistent::Error => e
        p e.inspect
      end
    end
    {emails: emails, phones: phones}
  end

  private

  def check_parameterized_record_list
    errors.add(:parameterized_record_list_id, ' must not be nil. ') if url_parameterization_type === "Data" && parameterized_record_list_id.nil?
  end

  def generate_record_list
    record_list = RecordList.new
    record_list.name = filename
    self.scraped_record_list = record_list
  end

  def scrape_page(url)

    set_agent_with_proxy
    uri = URI(url)
    response = @agent.get(uri)

    # print response from agent
    p "Response: "
    p response.inspect

    page = @agent.page
    page_uri = @agent.page.uri.to_s

    current_page = @agent.page
    puts "Scraping page: " + uri.to_s

    save_last_url(uri)

    # if root url has any parameters to scrape..
    scrape_sub_page(current_page, root_data_set) if root_data_set.present?

    sub_pages_data_sets.each do |sub_page|
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

    next_page(current_page, page_interval)
  rescue Net::HTTPNotFound
    next_page(current_page, page_interval)
  rescue Mechanize::ResponseCodeError => r
    if use_proxies
      puts "Unable to get to website with IP."
      puts "Proxy with IP " + @current_proxy.ip + " defective, deleting poxy.."
      push_to_defective @current_proxy
    end
    p r.inspect
    save_last_url(url)
  rescue Timeout::Error => t
    p "Timeout error: " + t.inspect
    sleep(3)
    retry
  rescue Exception => e
    p e.inspect
  end

  def url_parameter_array
    @url_parameter ||= parameterized_textarea.present? ? parameterized_textarea.split("\n") : parameterized_record_list.records
  end

  def next_page(current_page, page_interval)

    url_params = url_parameter_array

    if pagination_type === "PageLink"
      next_link = node_to_uri(current_page.search(next_selector).last) rescue nil
    else
      
      @page_index += 1

      if url_parameterization_type === "Integer"
        
        # use URL parameters to find next
        url_param = (page_interval * @page_index).to_s
      
      else
  
        # use next record in record list for parameter in URL
        url_param = (url_params[@page_index].text) rescue nil
      
      end

      p url_param.inspect

      next_link = url_param ? page_parameterized_url.gsub(":page", url_param) : nil

    end

    unless next_link.nil?
      puts "Clicked next link: " + next_link.to_s
      scrape_page(next_link)
    else
      puts "------------------- END ----------------"
    end
  end

  def set_agent_with_proxy(proxy = nil)
    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.keep_alive = true
      agent.open_timeout = 3
      agent.read_timeout = 3
      agent.max_history = 3

      if use_proxies
        @current_proxy = proxy.nil? ? get_random_proxy : proxy
        puts @current_proxy.to_s
        puts "Using proxy ip: " + @current_proxy.ip.to_s + ":" + @current_proxy.port.to_s
        agent.set_proxy @current_proxy.ip, @current_proxy.port
      end

      p "Agent set."
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
      puts "    Crawling page for data parameters"
      csv_row = []

      # create a record set if a data set exists
      record_set = data_set ? RecordSet.create!(data_set_id: data_set.id, scrape_id: id) : nil

      data_set.parameters.each do |parameter|
        data = page.search(parameter.selector).text.gsub("\t","").gsub("\n","").gsub(parameter.text_to_remove, "")
        unless data == "" || data.match(/^\s*$/i)
          csv_row.push data

          record_params = {
            record_type: parameter.name,
            record_list_id: scraped_record_list.id,
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

  def node_to_uri node
    uri = URI(node.attributes['href'].value.to_s).to_s
    if uri.match(/^(http|https):\/.+(\.(com|net|org|gov|it|biz))/).nil?
      @website_root + uri
    else
      uri
    end
  end

  def save_last_url(url = nil)
    last_scanned_url = url.to_s || @agent.page.uri.to_s
    save!
  end
end
