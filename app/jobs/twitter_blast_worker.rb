class TwitterBlastWorker
  require "mechanize"
  require "resque/errors"
  extend RetriedJob
  @queue = :twitter_queue

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
      @twitter_blast.get_followers_from_handles
    end

    def tweet_to from, to, message
      message = from.tweet(message, to)
      @twitter_blast.increment!(:messages_sent)
      record = Record.create!(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet")
    end

    def tweet_to_handles
      get_handles.each do |sn|
        to = sn.strip
        message = '@#{ to } #{ @twitter_blast.message }'
        tweet_to(@user, to, message) unless Record.where(text: message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
      end
    end

    def get_handles
      @handles ||= @twitter_blast.handles
    end

    def get_follows
      @follows ||= @twitter_blast.following_list_stringified
    end

    def unfollow_followed
      get_follows.each do |handle|
        @user.unfollow(handle)
      end
    end

    def unfollow_handles
      get_handles.each do |handle|
        @user.unfollow(handle)
      end
    end

    # follow handles on handle_list or from textarea
    def follow_handles
      @twitter_blast.follow_handles
    end

    def reset
      @twitter_blast.records.destroy_all
    end

    def blast!

      @twitter_blast.update_attributes(status: "Running")
      
      send(@twitter_blast.blast_type)

      @twitter_blast.status = "Stopped"
      @twitter_blast.save!
    rescue Exception => e
      p e.inspect
    end
  end
end