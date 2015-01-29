class CraigslistUser
	include Mongoid::Document
	include ScrapeHelpers
	include AdHelpers

	field :email, type: String
	field :password, type: String

	CRAIGSLIST_LOGIN_URL = "https://accounts.craigslist.org/login"

	# login to craiglsist using a phone verified account
	# return mechanize agent
	def login
		@agent ||= Mechanize.new
		@agent = set_proxy(@agent)
		@agent.get(CRAIGSLIST_LOGIN_URL)
		form = @agent.page.form("login") || @agent.page.forms[0]
		form.inputEmailHandle = email
		form.inputPassword = password
		form.submit
		@agent
	end
end