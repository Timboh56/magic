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
        @user = User.find(user_id["$oid"])
        blast!
      rescue Exception => e
        puts e.inspect
      end
    end


    def get_followers
      users = []

      if @twitter_blast.handles_type == "textarea"
        handles = @twitter_blast.twitter_handles.split(",")
      else
        handles = @twitter_blast.handle_list.handles.slice(0, @twitter_blast.limit)
      end

      handles.each do |handle|
        users.concat @user.get_followers(handle, @twitter_blast)
        sleep(3)
      end
      users
    end

    def tweet_to from, to, message
      message = from.tweet(message, to)
      @twitter_blast.increment!(:messages_sent)
      record = Record.create!(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet")
    end

    def tweet_to_followers
      get_followers.each do |follower|
        sn = follower.screen_name

        message = '@#{ to } #{ @twitter_blast.message }'

        tweet_to(@user, sn, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
        sleep(3)
      end
    end

    def tweet_to_handles
      get_handles.each do |sn|
        to = sn.strip
        message = '@#{ to } #{ @twitter_blast.message }'
        tweet_to(@user, to, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
      end
    end

    def follow_followers
      get_followers.each do |follower|
        @user.follow(follower.id)
      end
    end

    def get_handles
      @handles ||= @twitter_blast.handles_type == "textarea" ? @twitter_blast.twitter_handles.split(",") : @twitter_blast.handles_stringified
    end

    def follow_handles
      p "Follow handles"
      get_handles.each do |handle|
        @user.follow(handle)
      end
      p "Donzo"
    end

    def blast!

      @twitter_blast.update_attributes(status: "Running")

      @twitter_blast.records.destroy_all
      
      limit = @twitter_blast.limit

      send(@twitter_blast.blast_type)

      @twitter_blast.status = "Stopped"
      @twitter_blast.save!
    rescue Twitter::Error::TooManyRequests => error
      p error
      p 'Sleep ' + error.rate_limit.reset_in.to_s
      sleep error.rate_limit.reset_in
      retry
    rescue Exception => e
      p e
    end
  end
end