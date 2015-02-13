class Person
  include Mongoid::Document
  include CrunchbaseHelper
  include AugurHelper
  include Mongoid::Elasticsearch

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :google_id, type: String
  field :available, type: Boolean, default: true
  field :clearbit
  field :bio, type: String
  field :twitter_info, type: Hash
  field :twitter_screen_name, type: String
  field :angellist_info, type: Hash
  field :augur_info, type: Hash
  field :person_type, type: String # tutor
  field :website, type: String
  validates_uniqueness_of :name, case_sensitive: false
  validates_presence_of :name
  belongs_to :people_scrape

  def twitter_screen_name_to_augur
    if twitter_screen_name.present?
      augur_hash = search_with([{ "param_type" => "twitter_handle", "param" => twitter_screen_name }])
      self.augur_info = augur_hash
      save!
    end
  end
end