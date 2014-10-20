class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_handle, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0
  field :twitter_handles, :type => String
  field :blast_type, :type => String # followers or handles

  validates_length_of :message, maximum: 140

  has_many :records

  def twitter_client user
    user.twitter
  end

  def get_user_followers
  	twitter_client.followers(user_handle)
  end

  def tweet_to from, to

    #twitter_client.create_direct_message(follower, message)
    twitter_client(from).update("@#{ to } " + message)
    
    self.messages_sent = self.messages_sent + 1

    # create a record
    Record.create!(:twitter_blast_id => id, :record_type => "Twitter handle", :text => to)
  end

  def blast!(user)
    begin
      if blast_type == "followers"
        get_user_followers.each do |follower|
          sn = follower.screen_name
          puts "Tweeting to: " + sn
          tweet_to(user, sn)
        end
      else
        blast_type.split(",").each do |handle|
          tweet_to(user, handle.strip)
        end
      end
      save!
    rescue Exception => e 
      puts e.inspect
    end
  end
end