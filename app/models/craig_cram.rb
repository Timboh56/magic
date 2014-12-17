class CraigCram
	include Mongoid::Document
	include TwitterHelpers
	field :ad_contact_name, type: String
	field :ad_title, type: String
	field :ad_phone_number, type: String
	field :ad_postal_code, type: String
	field :ad_street, type: String
	field :ad_city, type: String
	field :ad_region, type: String
	field :cities_a_day, type: Integer, default: 20

	has_many :messages
	has_many :emails
	belongs_to :user

	accepts_nested_attributes_for :emails, allow_destroy: true
	accepts_nested_attributes_for :messages, allow_destroy: true

	CRAIGSLIST_CITIES = "https://geo.craigslist.org/iso/us"

	def run
    Resque.enqueue(CramJob, id)
	end

	def get_us_city_links
		agent = Mechanize.new
		agent.get(CRAIGSLIST_CITIES)
		city_links = agent.page.search("li").to_a[0,413].map { |li| li.children.first.attributes["href"].value }
	end

	# scheduled to run daily
	def post_to_cities
		if emails.present? && messages.present?
			city_links = get_us_city_links
			(1..cities_a_day).each do |i|
				post_to_form(emails[i % emails.length], messages[i % messages.length], city_links[i % city_links.length])
			end
		end
	end

	def get_ad_postal_code(city_name)
		city_name.to_zip.first rescue raise "Couldn't find a postal code from city name #{ city_name }"
	end

	def post_to_form(email_address, body, city_url, city_name = nil)
		p "Posting to: #{ city_url }"
		p "Email: #{ email_address }"
		p "Body: #{ body }"
		agent = Mechanize.new
		agent.get(city_url)
		agent.click(agent.page.link_with(:text => /post to classifieds/))
		agent.page.forms[0].radiobuttons_with(:value => "so").first.click()
		agent.page.forms[0].submit
		sleep_random
		agent.page.forms[0].radiobuttons_with(:value => "76").first.click()
		agent.page.forms[0].submit
		sleep_random
		agent.page.forms[0].radiobuttons[rand(5)].click()
		agent.page.forms[0].submit
		sleep_random
		agent.page.forms[0].fields[0].value = email_address # required
		agent.page.forms[0].fields[1].value = email_address # required
		agent.page.forms[0].fields[2].value = ad_phone_number
		agent.page.forms[0].fields[3].value = ad_contact_name
		agent.page.forms[0].fields[4].value = ad_title
		agent.page.forms[0].fields[6].value = ad_postal_code || get_ad_postal_code(city_name) # required
		agent.page.forms[0].fields[9].value = ad_city || city_name
		agent.page.forms[0].fields[13].value = body
		agent.page.forms[0].submit
		sleep_random
		agent.page.forms[0].submit
		p "Complete!"
	rescue Exception => e
		p "Error: #{ e.inspect }"
	end
end