class CraigCram
  include Mongoid::Document
  include ScrapeHelpers
  include AdHelpers
  
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

  def set_emails
    if textarea_or_db == "db"
      (0..(cities_a_day - 1)).each do |i|
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
  # there should roughly be as many cities as there are emails
  def post_to_cities!
    set_emails
    cl_uris = []
    if emails.present? && messages.present?

      # us_cities = CRAIGSLIST_CITIES_URLS
      craigslist_users = CraigslistUser.all
      cities_post_to = cities_a_day > craigslist_users.length ? craigslist_users.length : cities_a_day
      (0..(cities_post_to - 1)).each do |i|
        p = post_to_city(emails[(city_index + i) % emails.length].email, messages[i % messages.length], craigslist_users[i])
        emails[(city_index + i) % emails.length].update_attributes!(used: true)
        cl_uris << p.uri
      end
      self.city_index += cities_post_to
    end
    save!
    cl_uris
  end

  def get_ad_postal_code(city_name)
    zip_codes = city_name.match("/").present? ? city_name.split("/").first.strip.to_zip : city_name.to_zip
    return zip_codes.present? ? zip_codes.first : "90065"
  end

  def create_listing_body(listing)
    p "Creating randomized listing body.."

    listing_body = listing.text + " \n " + sentence_rearranger(listing.randomized_text) + " \n " + random_greeting
    create_listing_body(listing) if Record.where(text: listing_body).exists?
    listing_body
  end

  def post_to_city(email_address, listing, cl_user)
    
    p "Login"

    agent = cl_user.login
    
    p "Posting to: #{ cl_user.city }"
    p "Posting to url: #{ cl_user.city_url } "
    p "Posting type: #{ posting_type }"
    p "Email: #{ email_address }"
    p "Title: #{ listing.title }"

    listing_body = create_listing_body(listing)

    p "Body: #{ listing_body }"

    agent.get(cl_user.city_url)
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
    
    fill_form(agent.page.forms[0], email_address, listing.title || ad_title, cl_user, listing_body, get_ad_postal_code(cl_user.city))
  
    sleep_random

    go_to_next_til_done(agent)

    # for debuggin
    p agent.page.uri

    p "Complete!"

    Record.create!(text: listing_body)

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

  def fill_form(form, email_address, title, body, postal_code)
    form.email = email_address
    form.phone = ad_phone_number
    form.postal = postal_code
    form.body = body
    form.contact_name  = ad_contact_name
    form.postingTitle = title
    form.remuneration = random_compensation
    find_radio_button(form, "pay").click rescue p "No radio button for paying found."
  end
end