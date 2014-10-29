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

      if @twitter_blast.handles_types == "textarea"
        handles = @twitter_blast.twitter_handles.split(",")
      else
        handles = @twitter_blast.handle_list.handles.slice(0, @twitter_blast.limit)
      end

      handles.each do |handle|
        users.concat user.get_followers(handle, @twitter_blast)
        sleep(3)
      end

      users
    end

    def tweet_to from, to, message
      message = from.tweet(message, to)
      @twitter_blast.increment!(:messages_sent)
      record = Record.create!(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet")
    end

    def blast!(user)

      @twitter_blast.update_attributes(status: "Running")

      @twitter_blast.records.destroy_all
      
      limit = @twitter_blast.limit

      case @twitter_blast.blast_type
      when "tweet_to_followers"
        get_users_followers(user).each do |follower|
          sn = follower.screen_name

          message = '@#{ to } #{ @twitter_blast.message }'

          tweet_to(user, sn, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
          sleep(3)
        end
      when "tweet_to_handles"
        handles = @twitter_blast.handles_type == "textarea" ? @twitter_blast.twitter_handles.split(",") : @twitter_blast.handle_list.handles
        handles.each do |sn|
          to = sn.strip
          message = '@#{ to } #{ @twitter_blast.message }'
          tweet_to(user, to, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
        end
      when "follow_followers"
        get_users_followers(user).each do |follower|
          user.twitter_client.follow(follower.id)
        end
      when "follow_handles"
        handles = @twitter_blast.handles_type == "textarea" ? @twitter_blast.handle_list.handles : @twitter_blast.twitter_handles.split(",")
        handles.each do |handle|
          user.twitter_client.follow(handle)
        end
      when "get_followers"
        handles = @twitter_blast.handles_type == "textarea" ? @twitter_blast.handle_list.handles : @twitter_blast.twitter_handles.split(",")
        handles.each do |handle|
          user.twitter_client.users(handle)
        end
      end

      @twitter_blast.status = "Stopped"
      @twitter_blast.save!
    end
  end
end