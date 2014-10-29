class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  field :text, type: String
  belongs_to :twitter_blast
end