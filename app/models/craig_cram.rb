class CraigCram
  include Mongoid::Document
  include ScrapeHelpers
  field :ad_contact_name, type: String
  field :ad_title, type: String
  field :ad_phone_number, type: String
  field :ad_postal_code, type: String
  field :ad_street, type: String
  field :ad_city, type: String
  field :ad_region, type: String
  field :cities_a_day, type: Integer, default: 20
  field :city_index, type: Integer, default: 0
  field :category, type: String
  field :posting_type, type: String, default: "go"
  field :textarea_or_db, type: String, default: "db"
  has_many :messages, autosave: true
  has_many :emails, autosave: true
  belongs_to :user

  accepts_nested_attributes_for :emails, allow_destroy: true
  accepts_nested_attributes_for :messages, allow_destroy: true

  CRAIGSLIST_CITIES = "https://geo.craigslist.org/iso/us"

  def run
    Resque.enqueue(CramJob, id)
  end

  def mechanize_agent
    @agent ||= lambda {
      agent = Mechanize.new
      set_proxy(agent)
      agent
    }.call
  end

  def set_emails
    if textarea_or_db == "db"
      (0..cities_a_day).each do |i|
        emails << Email.unused[i]
      end
      save!
    end
  end

  def get_us_cities
    mechanize_agent.get(CRAIGSLIST_CITIES)
    city_links = mechanize_agent.page.search("li").to_a[0,413].map { |li| { city_name: li.children.first.children.first.text , url: li.children.first.attributes["href"].value } }
  end

  # scheduled to run daily
  def post_to_cities
    set_emails
    cl_uris = []
    if emails.present? && messages.present?
      us_cities = get_us_cities
      (city_index..cities_a_day).each do |i|
        p = post_to_city(emails[i % emails.length].email, messages[i % messages.length], us_cities[i % us_cities.length])
        emails[i % emails.length].update_attributes!(used: true)
        cl_uris << p.uri
      end
    end
    cl_uris
  end

  def get_ad_postal_code(city_name)
    zip_codes = city_name.match("/").present? ? city_name.split("/").first.strip.to_zip : city_name.to_zip
    return zip_codes.present? ? zip_codes.first : "90065"
  end

  def post_to_city(email_address, listing, city)
    
    agent = mechanize_agent

    p "Posting to: #{ city[:city_name] }"
    p "Posting to url: #{ city[:url] } "
    p "Posting type: #{ posting_type }"
    p "Email: #{ email_address }"
    p "Title: #{ listing.title }"
    p "Body: #{ listing.text }"

    agent.get(city[:url] )
    agent.click(agent.page.link_with(:text => /post to classifieds/))

    p "Selecting posting type.."

    select_post_type(agent)

    p "Selecting category 1.."

    agent.page.forms[0].submit

    sleep_random

    p "Selecting category 2.."

    select_category(agent)

    sleep_random

    p "Selecting closest location.."

    # select location
    select_nearest_location(agent.page.forms[0], ad_region) if agent.page.title.match("choose nearest area")

    sleep_random

    p "Filling form.."

    fill_form(agent.page.forms[0], email_address, listing.title || ad_title, city, listing.text, get_ad_postal_code(city[:city_name]) || ad_postal_code)
  
    sleep_random

    go_to_next_til_done(agent)

    # for debuggin
    p agent.page.uri

    p "Complete!"
    agent.page
  rescue Exception => e
    p "Error: #{ e.inspect }"
    agent.page
  end

  # recursively clicks on "next/continue/publish" buttons until
  # it reaches the last page
  def go_to_next_til_done(agent)

    p "Going to next page.."
    
    go_to_next(agent)

    sleep_random

    go_to_next_til_done(agent) if agent.page.forms.present?
  end

  def go_to_next(agent)
    if agent.page.forms.present? && agent.page.forms.count > 1
      form_btn = find_form_button(agent, { value: /done with images|continue|publish/i })
      agent.submit(form_btn[0], form_btn[1])
    elsif agent.page.forms.count == 1
      agent.page.forms[0].submit
    end
  end

  def select_category(agent)

    # choose category
    find_radio_button(agent.page.forms[0], category).click

    agent.page.forms[0].submit
  end

  def select_post_type(agent)

    # posting type page
    agent.page.forms[0].radiobuttons_with(:value => posting_type).first.click
    agent.page.forms[0].submit
  end

  def select_nearest_location(agent, location = nil)
    if location
      find_radio_button(agent.page.forms[0], location).click
    else
      agent.page.forms[0].radiobuttons[0].click
    end
    agent.page.forms[0].submit
  end

  def fill_form(form, email_address, title, city, body, postal_code)
    fill_form_fields(form.fields, "email", email_address)
    fill_form_fields(form.fields, "phone", ad_phone_number)
    fill_form_fields(form.fields, "postal", postal_code)
    fill_form_fields(form.fields, "body", body)
    fill_form_fields(form.fields, "contact_name", ad_contact_name)
    fill_form_fields(form.fields, "postingtitle", title)
    fill_form_fields(form.fields, "remuneration", "$50/hr")
    find_radio_button(form, "pay").click rescue p "No radio button for paying found."
  end

  def find_form_button(agent, opts)
    form_btn = nil
    agent.page.forms.each do |form|
      if (btn = form.button_with(opts)).present?
        form_btn = [form, btn]
        break
      end
    end
    form_btn
  end

  def fill_form_fields(form_fields, field_name, value)
    form_fields.select { |f| f.name.match(/#{ field_name }/i) }.each do |field|
      field.value = value
    end
  end

  def find_radio_button(page_form, text = nil)
    if text.present?
      page_form.radiobuttons.select { |r| r.node.parent.text.strip.match(text) }.first
    else
      page_form.radiobuttons.first
    end
  end

  def set_proxy(agent)
    proxies = ProxyHost.all
    random_proxy = proxies[rand(proxies.count)]
    agent.set_proxy random_proxy.ip, random_proxy.port
    p "Proxy set: #{ random_proxy.ip }:#{ random_proxy.port }"
    agent
  end
end