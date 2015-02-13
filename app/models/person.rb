class Person
  include Mongoid::Document
  include CrunchbaseHelper
  include AugurHelper
  include Mongoid::Elasticsearch
  include CSVHelper

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
  field :angellist_info, type: Hash

  has_one :augur_profile

  validates_uniqueness_of :name, case_sensitive: false
  validates_presence_of :name

  scope :investors, lambda { where(investor: true) }
  scope :with_twitter, lambda { where(:twitter_screen_name.exists => true, :twitter_screen_name.ne => "") }

  def twitter_screen_name_to_augur!
    if twitter_screen_name.present?
      search_with([{ "param_type" => "twitter_handle", "param" => twitter_screen_name }])
    end
  rescue Exception => e
    p e.inspect
  end
end