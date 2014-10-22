class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :user_handle, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0
  field :twitter_handles, :type => String
  field :blast_type, :type => String # followers or handles

  validates_length_of :message, maximum: 140

  has_many :records

  def get_users_followers user
    cursor = -1
    users = []
    begin
      twitter_handles.split(",").each do |handle|
        while(cursor != 0)
          result = user.twitter_client.followers(handle, "cursor" => "#{ cursor }")
          cursor = result.next_cursor
          users.concat! result.users
          sleep(3)
        end
      end
      users
    rescue Exception => e 
      puts e.inspect
      raise e
    end
  end

  def tweet_to from, to

    #twitter_client.create_direct_message(follower, message)
    response = from.twitter_client.update("@#{ to } " + message)

    self.messages_sent = self.messages_sent + 1

    # create a record
    Record.create!(:twitter_blast_id => id, :record_type => "Twitter handle", :text => to)
  end

  def blast!(user)
    records.destroy_all
    if blast_type == "followers"
      get_users_followers(user).each do |follower|
        sn = follower.screen_name
        tweet_to(user, sn)
      end
    elsif blast_type == "handles"
      twitter_handles.split(",").each do |sn|
        tweet_to(user, sn.strip)
      end
    elsif blast_type == "get_followers"
      get_users_followers(user).each do |sn|
        Record.create!(:twitter_blast_id => id, :record_type => "Twitter handle", :text => sn)
      end
    end
    save!
  end
end