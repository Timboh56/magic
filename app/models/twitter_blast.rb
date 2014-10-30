class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  field :name, type: String
  field :status, type: String
  field :message, type: String
  field :messages_sent, type: Integer, default: 0
  field :twitter_handles, type: String
  
  # get_followers, tweet_to_handles, follow_handles, unfollow_handles
  field :blast_type, type: String # followers or handles
  
  field :limit, type: Integer, default: 1000
  field :handles_type, type: String, default: "textarea" # textarea or list
  validates_length_of :message, maximum: 140

  has_many :records, :dependent => :destroy
  has_many :messages
  belongs_to :handle_list
  belongs_to :user

  scope :follow_handles, lambda { where(blast_type: "follow_handles") }
  scope :direct_messages, lambda { where(blast_type: "direct_messages") }
  before_create :create_handle_list

  def direct_message_follow_backs

    # direct message followed users
    records.follows.each do |follow|

      # if direct message hasn't been sent
      unless records.direct_messages.where(to: follow.text).exists?
        
        user.direct_message(follow, message)
        Record.create!(twitter_blast_id: id, record_type: "DirectMessage", to: follow, text: message)
      end
    end
  end

  def follows
    records.follows
  end

  # return array of handles of each record of
  # user followed
  def follows_list_stringified
    follows.take(limit).map! { |h| h.text }
  end

  # return array of handles of each record
  # of user acquired
  def handles_list_stringified
    handle_list.handles.take(limit).map! { |h| h.text }
  end

  def handles
    @handles ||= handles_type == "textarea" ? twitter_handles.split(",") : handles_list_stringified
  end

  def blast!
    Resque.enqueue(TwitterBlastWorker, id, user_id, limit)
  end

  def handles_array
    twitter_handles.present? ? twitter_handles.split(",") : nil
  end

  def handle_records_count
    records.present? ? records.handles.count : 0
  end

  def create_handle_list
    if handles_type == "list" && handle_list_id.nil?
      handle_list = HandleList.new
      handle_list.name = name
      handle_list.handles = records.handles
      handle_list.save!
      handle_list_id = handle_list.id
    end
  end
end