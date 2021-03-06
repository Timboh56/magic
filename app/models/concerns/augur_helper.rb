module AugurHelper
	extend ActiveSupport::Concern
	require 'mechanize'

	# param_type
	# "twitter_handle", "email", "facebook_handle", "uid" (augur uid)
	# "angellist_handle"
	# https://api.augur.io/v2/user?key=ejztei8l6y99r1ser9x9rmhbml8mnivm&
	# params = [{
	# 	"param_type" => "email"
	#   "param" => "timboh56@gmail.com"
	# }, ...]
	def search_with(params)
		api_key = ENV['AUGUR_API_KEY']
		augur_endpt = params.inject("https://api.augur.io/v2/user?key=#{ api_key }") { |str,p| str += "&#{ p["param_type"] }=#{ p["param"] }" }
		augur_endpt += "&webhook=http://dopemagic.com/augur_profiles"
		a = Mechanize.new
		JSON.parse(a.get(augur_endpt).body).to_hash
	end
end