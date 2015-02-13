class Person
  include Mongoid::Document
  include CrunchbaseHelper

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :google_id, type: String
  field :available, type: Boolean, default: true
  field :clearbit
  field :bio, type: String
  field :twitter_info, type: Hash
  field :angellist_info, type: Hash
  field :augur_info
  field :person_type, type: String # tutor
  field :website, type: String
  validates_uniqueness_of :name, case_sensitive: false
  validates_presence_of :name
  belongs_to :people_scrape
end