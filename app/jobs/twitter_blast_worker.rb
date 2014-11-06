class TwitterBlastWorker
  require "mechanize"
  require "resque/errors"
  extend RetriedJob
  @queue = :twitter_queue

  class << self
    def perform(id, user_id)
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

    def tweet_to_handles
      @twitter_blast.tweet_to_handles
    end

    def get_handles
      @handles ||= @twitter_blast.handles
    end

    def get_follows
      @follows ||= @twitter_blast.following_list_stringified
    end

    def unfollow_handles
      @twitter_blast.unfollow_handles
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