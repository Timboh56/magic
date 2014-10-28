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
        results = user.twitter_client.follower_ids(handle)
        results.to_a.each_slice(100).each do |follower_ids|
          followers = user.twitter_client.users(follower_ids)

          followers.each do |follower|

            p "Got follower information: " + follower.inspect
            users.push follower
          
            record_params = {
              twitter_blast_id: @twitter_blast.id,
              record_type: "Handle",
              text: follower.screen_name,
            }

            unless Record.where(record_params).exists?
            
              # create a record
              record = Record.create!(record_params.merge!({ handle_list_id: @twitter_blast.handle_lists.first.id }))
            
              p "Created record: " + record.inspect
            end
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

    def tweet_to from, to, message

      tweet = "@#{ to } #{@twitter_blast.message}"
      response = from.twitter_client.update(tweet)

      @twitter_blast.increment!(:messages_sent)

      record = Record.new(text: tweet, twitter_blast_id: @twitter_blast.id, record_type: "Tweet")
      record.save!
    end

    def blast!(user, n = nil)

      @twitter_blast.status = "Running"
      @twitter_blast.save!

      @twitter_blast.records.destroy_all
      if @twitter_blast.blast_type == "followers"
        followers = n ? get_users_followers.take(n) : get_users_followers

        followers.each do |follower|
          sn = follower.screen_name
          tweet_to(user, sn) unless Record.where(text: @twitter_blast.message, twitter_blast_id: @twitter_blast.id, record_type: "Tweet").exists?
          sleep(3)
        end
      elsif @twitter_blast.blast_type == "handles"
        twitter_handles.split(",").each do |sn|
          tweet_to(user, sn.strip)
        end
      elsif @twitter_blast.blast_type == "get_followers"
        get_users_followers(user)
      end

      @twitter_blast.status = "Stopped"
      @twitter_blast.save!
    end
  end
end