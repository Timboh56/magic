module CrunchbaseHelper
	extend ActiveSupport::Concern
  require 'crunchbase-api'
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
			team_members.push(p = Person.create!(name: name))
		end
		team_members
  end
end