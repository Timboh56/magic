class Person
  include Mongoid::Document
  include CrunchbaseHelper
  include AugurHelper
  include CSVHelper
  include Mongoid::Search

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :google_id, type: String
  field :organization, type: String
  field :available, type: Boolean, default: true
  field :clearbit
  field :bio, type: String
  field :twitter_screen_name, type: String
  field :person_type, type: String # tutor
  field :website, type: String
  field :investor, type: Boolean
  field :twitter_info, type: Hash
  field :facebook_screen_name, type: String
  field :angellist_info, type: Hash

  has_one :augur_profile
  belongs_to :people_scrape

  validates_uniqueness_of :name, case_sensitive: false
  validates_presence_of :name

  scope :investors, lambda { where(investor: true) }
  scope :with_twitter, lambda { where(:twitter_screen_name.exists => true, :twitter_screen_name.ne => "") }
  search_in :email, :name, :bio, :augur_profile => :data

  def self.investors_csv
    CSVHelper.collection_to_csv(investors_with_profiles.take(1000))
  end

  def self.investors_with_profiles
    p 'investors with profiles'

    i = Person.investors.with_twitter.select! { |p| p.augur_profile.present? }
    p i.inspect
    p ' OK?'
    i
  end

  def self.completed_profiles
    AugurProfile.ne(person_id: nil).map(&:person)
  end
  
  def twitter_screen_name_to_augur!
    if twitter_screen_name.present?
      search_with([{ "param_type" => "twitter_handle", "param" => twitter_screen_name }])
    end
  rescue Exception => e
    p e.inspect
  end
end