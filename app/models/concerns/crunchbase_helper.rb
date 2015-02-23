module CrunchbaseHelper
	extend ActiveSupport::Concern
  require 'crunchbase-api'
  require 'mechanize'
  Crunchbase.user_key = '6b3f2867455f662d20cb93a9370247c8'

  def get_organization(organization_name)
		organization = Crunchbase::Organization.get(organization_name)
  end

  def get_team_members_names(organization_name)
		organization = get_organization(organization_name)
		organization.current_team.map! { |c| c.path.gsub("person/","").gsub("-"," ") }
  end

  def save_team_members(organization_name)
  	team_members = []
		get_team_members_names(organization_name).each do |name|
			team_members.push(p = Person.create!(name: name, organization: organization_name))
		end
		team_members
  end

  def organization_name_to_url

  end

  def get_email(name, organization_domain)
    toofr_api_key = "a5faa3fa7ab99f0fad8ca3aef0c87b7e"
    first_name = name.split(" ")[0]
    last_name = name.split(" ")[1]
    a = Mechanize.new
    url = 'http://toofr.com/api/guess?key=#{ toofr_api_key }&domain=#{ organization_domain }&first=#{ first_name }&last=#{ last_name }'
    JSON.parse(a.get(url).body)
  end
end

# http://toofr.com/api/guess?key=<< api key here >>&domain=toofr.com&first=ryan&last=buckley