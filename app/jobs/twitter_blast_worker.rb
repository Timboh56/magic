class TwitterBlastWorker
  require "mechanize"
  @queue = :scraper_queue

  class << self
    def perform(id, user_id)
      unless id.is_a? String
        @twitter_blast = TwitterBlast.find(id["$oid"])
      else
        @twitter_blast = TwitterBlast.find(id)
      end
      user = User.find(user_id["$oid"])
      blast!(user)
    end

    def get_users_followers user
      users = []
      @twitter_blast.twitter_handles.split(",").each do |handle|
        results = user.twitter_client.follower_ids(handle)
        results.to_a.each_slice(100).each do |follower_ids|
          followers = user.twitter_client.users(follower_ids)

          followers.each do |follower|
            puts "Got follower information: " + follower.inspect
            users.push follower
          
            # create a record
            record = Record.create!(:twitter_blast_id => @twitter_blast.id, :record_type => "Twitter handle", :text => follower.screen_name)
            
            p "Created record: " + record.inspect

          end
        end
        sleep(3)
      end
      users
    rescue Twitter::Error::TooManyRequests => error
      p error
      p 'Sleep ' + error.rate_limit.reset_in.to_s
      sleep error.rate_limit.reset_in
      retry
    end

    def tweet_to from, to

      response = from.twitter_client.update("@#{ to } " + message)

      self.messages_sent = self.messages_sent + 1
    end

    def blast!(user)
      @twitter_blast.records.destroy_all
      if @twitter_blast.blast_type == "followers"
        get_users_followers(user).each do |follower|
          sn = follower.screen_name
          tweet_to(user, sn)
          sleep(3)
        end
      elsif @twitter_blast.blast_type == "handles"
        twitter_handles.split(",").each do |sn|
          tweet_to(user, sn.strip)
        end
      elsif @twitter_blast.blast_type == "get_followers"
        get_users_followers(user)
      end
      @twitter_blast.save!
    end
  end
end