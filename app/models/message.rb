class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :text, type: String
  field :randomized_text, type: String
  belongs_to :twitter_blast
  belongs_to :user_tinder_bot
  belongs_to :craig_cram
end