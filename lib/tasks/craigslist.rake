namespace :craigslist do

	require 'rubygems'
	require 'nokogiri'
	require 'open-uri'
	require 'mechanize'

	CRAIGSLIST_URL = "http://losangeles.craigslist.org/"
	AD_EMAIL_ADDRESS = "timboh56@gmail.com"
	AD_TITLE = "Web developer/designer needed"
	AD_POSTAL = "90046"
	AD_CITY = "Los Angeles"
	AD_REGION = "West Hollywood"
	AD_BODY = "We are looking for a competent web developer/designer to help us build our online commerce site. We need someone with good experience and great portfolio of online shops. Must be proficient in. \n \n a. Photoshop \n b. Word Press Templates \n c. Wazala.com online stores \n d. Google Analytics \n e. Google Adwords \n \n Please send portfolio links and rates for a complete commerce buildout package. We are looking for a full service deal. You must help design, build and train us on using the system. We will do the data entry and upload of images etc. \n Thanks and god bless."

	agent = Mechanize.new
	agent.get(CRAIGSLIST_URL)
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
	agent.page.forms[0].fields[0].value = AD_EMAIL_ADDRESS # required
	agent.page.forms[0].fields[1].value = AD_EMAIL_ADDRESS # required
	agent.page.forms[0].fields[2].value = AD_CONTACT_PHONE
	agent.page.forms[0].fields[3].value = AD_CONTACT_NAME
	agent.page.forms[0].fields[4].value = AD_TITLE
	agent.page.forms[0].fields[5].value = AD_REGION	
	agent.page.forms[0].fields[6].value = AD_POSTAL # required
	agent.page.forms[0].fields[7].value = AD_STREET
	agent.page.forms[0].fields[9].value = AD_CITY
	agent.page.forms[0].fields[13].value = AD_BODY
	agent.page.forms[0].submit
	agent.page.forms[0].submit
	sleep_random
	p agent.page.inspect

	def sleep_random
	sleep(rand(10))
	end
end