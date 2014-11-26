class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable
  include TwitterHelpers

  field :message, type: String
  field :messages_sent, type: Integer, default: 0
  field :twitter_handles, type: String
  field :follow_index, type: Integer, default: 0

  # get_followers, tweet_to_handles, follow_handles, unfollow_handles
  field :blast_type, type: String # followers or handles
  
  field :limit, type: Integer, default: 500
  field :handles_type, type: String, default: "textarea" # textarea or list
  
  validates_length_of :message, maximum: 140
  validates_presence_of :user_id

  # records of twitter blast - a tweet, a direct message,
  # a follow, unfollow, or handle retrieved.
  has_many :records, :dependent => :destroy

  has_many :messages
  belongs_to :handle_list
  belongs_to :user

  scope :follow_handles, lambda { where(blast_type: "follow_handles") }

  before_create :create_handle_list

  # direct message ppl who followed back
  # as a result of twitter blast with type follow_handles
  def direct_message_followers(message_body = nil)
    user.direct_message_followers(message, user.name, self) if message.present?
  end

  # unfollow any user we are following
  # not following us back
  def unfollow_following_not_followers

    # get list of followers
    followers_list = followers_list_stringified
    
    # get list of following
    following_list = following_list_stringified

    rate_limit = following_list.count > 2000 ? RateLimits::UNFOLLOW_LIMIT :  RateLimits::UNFOLLOW_LIMIT_UNDER_2000

    # unfollow handles on following not on followers
    (following_list - followers_list).take(rate_limit).each do |handle|

      p "Unfollowing " + handle.to_s

      user.unfollow(handle)
      
      r = Record.create!({
        twitter_blast_id: id,
        text: handle,
        record_type: "Unfollow",
        user_id: user_id
      })

      sleep_random
    end
  end

  def get_followers(handle = nil)
    user.get_followers_or_following("followers", handle, self)
  end

  def daily_follow_rate_limit
    @daily_follow_rate_limit ||= user.follower_count < 2000 ? RateLimits::FOLLOW_LIMIT_UNDER_2000 : RateLimits::FOLLOW_LIMIT
  end

  def get_followers_from_handles
    users = []

    if handles_type == "textarea"
      handles = twitter_handles.split(",")
    else
      handles = handle_list.handles.slice(0, limit)
    end

    handles.each do |handle|
      users.concat user.get_followers_or_following("followers", handle, self)
      sleep_random
    end
    users
  end

  def follow_handles

    p "Following handles.."

    if follow_index < (handles.count - 1)

      # number of handles already followed today from other accounts
      handles_followed_today = user.todays_follow_count

      # manual limit on how many follows a day
      follow_limit = daily_follow_rate_limit
      
      handles.slice(follow_index, (follow_index + follow_limit)).each do |handle|

        p "Follow index: #{ follow_index } "

        record_params = {
          twitter_blast_id: id,
          text: handle,
          record_type: "Friendship",
          user_id: user_id
        }
        
        begin

          if handles_followed_today > limit || handles_followed_today === follow_limit
            p "More handles followed than limit! Stopping.."
            break
          end

          unless Record.where(record_params).exists?
            
            user.follow(handle)

            # create record of follow
            r = Record.create!(record_params)

            p "Record created: " + r.inspect

            handles_followed_today += 1

            # sleep for random secs (< 10)
            sleep_random
            
          else
            p "User #{ handle } already followed, skipping.."
          end

          # increment follow index
          self.follow_index += 1
          save!

        rescue Twitter::Error::Forbidden => error
          p "Twitter error: Forbidden"

          # create record so we can skip this user
          r = Record.create!(record_params)

          update_attributes!(status: error.inspect)
        rescue Twitter::Error::RequestTimeout => error
          p "Request timed out!"
          update_attributes!(status: error.inspect)
        rescue Twitter::Error::TooManyRequests => error
          p error
          p 'Sleep ' + error.rate_limit.reset_in.to_s
          sleep error.rate_limit.reset_in
          update_attributes!(status: error.inspect)
          retry
        end
      end
    else
      p "All handles followed."
    end
    p "Donezo"
  end

  def following
    records.follows
  end

  def get_following(handle = nil)
    user.get_followers_or_following("friends", handle, self)
  end

  # return array of handles of each 
  # user that followedget_followers_or_following back
  def followers_list_stringified
    get_followers.map! { |f| f.screen_name }
  end

  # return array of handles of each record of
  # user followed
  def following_list_stringified
    get_following.map! { |f| f.screen_name }
  end

  def tweet_to_handles
    handles.each do |sn|
      tweet_to(sn.strip)
    end
  end

  def tweet_to(to)

    # format with handle
    formatted_tweet = '@#{ to.gsub("@","") } #{ message }'

    tweet_params = {
      text: formatted_tweet,
      twitter_blast_id: id,
      record_type: "Tweet",
      user_id: user_id,
      to: to
    }

    # unless user has been tweeted to before
    unless Record.where(tweet_params).exists?

      user.tweet(formatted_tweet, to)
      
      increment!(:messages_sent)

      # create record of tweet
      record = Record.create!(tweet_params)
    end
  end

  # return array of handles of each record
  # of user acquired
  def handles_list_stringified
    handle_list.handles.map! { |h| h.text }
  end

  # handles used for blast
  def handles
    @handles ||= handles_type == "textarea" ? twitter_handles.split(",") : handles_list_stringified
  end

  # run background task
  def run
    Resque.enqueue(TwitterBlastWorker, id, user_id, blast_type)
  end

  # run background task for unfolow
  def unfollow
    Resque.enqueue(TwitterBlastWorker, id, user_id, "unfollow")    
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