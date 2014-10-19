class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include TwitterHelper

  field :user_handle, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0

  def get_user_followers
  	twitter_client.followers(user_handle)
  end

  def blast!
    get_user_followers.each do |follower|
      puts "Sending message to: " + follower.screen_name
      twitter_client.create_direct_message(follower, message)
      messages_sent += 1
    end
    save!
  end
end