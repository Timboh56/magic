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
  field :facebook_screen_name, type: String
  field :linkedin_screen_name, type: String
  field :twitter_info, type: Hash
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
    Person.investors.with_twitter.select! { |p| p.augur_profile.present? }
  end

  def self.complete_profiles
    AugurProfile.ne(person_id: nil).map(&:person)
  end

  def self.incomplete_profiles
    AugurProfile.where(person_id: nil).map(&:person)
  end
  
  def twitter_screen_name_to_augur!(screen_name = nil)
    screen_name ||= twitter_screen_name
    if screen_name
      search_with([{ "param_type" => "twitter_handle", "param" => screen_name }])
    end
  rescue Exception => e
    p e.inspect
  end
end