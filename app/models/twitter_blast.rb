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

  # records of twitter blast - a tweet, a direct message,
  # a follow, unfollow, or handle retrieved.
  has_many :records, :dependent => :destroy

  has_many :messages
  belongs_to :handle_list
  belongs_to :user

  scope :follow_handles, lambda { where(blast_type: "follow_handles") }

  before_create :create_handle_list


  # unfollow any user we are following
  # not following us back
  def unfollow_following_not_followers

    # get list of followers
    followers_list = get_followers.map { |f| f.screen_name }
    
    # get list of following
    following_list = following_list_stringified

    # unfollow handles on following not on followers
    # limit to 250 unfollows a day
    (following_list - followers_list).take(250).each do |handle|

      p "Unfollowing " + handle.to_s

      user.unfollow(handle)

      sleep(3)
    end
  end

  def get_followers(handle = nil)
    user.get_followers(handle, self)
  end

  def following
    records.follows
  end

  # return array of handles of each 
  # user that followed back
  def followers_list_stringified
    get_followers.map! { |f| f.screen_name }
  end

  # return array of handles of each record of
  # user followed
  def following_list_stringified
    following.take(limit).map! { |h| h.text }
  end

  # return array of handles of each record
  # of user acquired
  def handles_list_stringified
    handle_list.handles.take(limit).map! { |h| h.text }
  end

  # handles used for blast
  def handles
    @handles ||= handles_type == "textarea" ? twitter_handles.split(",") : handles_list_stringified
  end

  # run background task
  def blast!
    Resque.enqueue(TwitterBlastWorker, id, user_id, limit)
  end

  def handles_array
    twitter_handles.present? ? twitter_handles.split(",") : nil
  end

  # number of handles retrieved from blast
  def handle_records_count
    records.present? ? records.handles.count : 0
  end

  # a twitter blast can use a handle list
  # or create a handle list for use in the future
  # create_handle_list creates a new handle list if
  # action is to get followers of handle
  def create_handle_list
    if blast_type == "get_followers"
      handle_list = HandleList.new
      handle_list.name = name
      handle_list.handles = records.handles
      handle_list.save!
      self.handle_list_id = handle_list.id
      p handle_list.inspect
      p "handle list created"
    end
  end
end