class TwitterBlastWorker
  require "mechanize"
  @queue = :scraper_queue

  class << self
    def perform(id, user_id, limit = nil)
      begin
        unless id.is_a? String
          @twitter_blast = TwitterBlast.find(id["$oid"])
        else
          @twitter_blast = TwitterBlast.find(id)
        end
        user = User.find(user_id["$oid"])
        blast!(user)
      rescue Exception => e
        puts e.inspect
      end
    end

    def get_users_followers user
      users = []
      @twitter_blast.twitter_handles.split(",").each do |handle|
        users = user.get_followers(handle, @twitter_blast)
        sleep(3)
      end
      users
    rescue Twitter::Error::TooManyRequests => error
      p error
      p 'Sleep ' + error.rate_limit.reset_in.to_s
      sleep error.rate_limit.reset_in
      retry
    end

    def tweet_to from, to, message
      message = from.tweet(message, to)
      @twitter_blast.increment!(:messages_sent)
      record = Record.create!(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet")
    end

    def blast!(user, n = nil)

      @twitter_blast.update_attributes(status: "Running")

      @twitter_blast.records.destroy_all
     
      followers = n ? get_users_followers(user).take(n) : get_users_followers(user)

      if @twitter_blast.blast_type == "followers"
        followers.each do |follower|
          sn = follower.screen_name

          message = '@#{ to } #{ @twitter_blast.message }'

          tweet_to(user, sn, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
          sleep(3)
        end
      elsif @twitter_blast.blast_type == "handles"
        
        @twitter_blast.twitter_handles.split(",").each do |sn|
        
          to = sn.strip
          message = '@#{ to } #{ @twitter_blast.message }'

          tweet_to(user, to, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
        end
      elsif @twitter_blast.blast_type == "follow_followers"
        followers.each do |follower|
          user.twitter_client.follow(follower.id)
        end
      end

      @twitter_blast.status = "Stopped"
      @twitter_blast.save!
    end
  end
end