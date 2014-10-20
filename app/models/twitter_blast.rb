class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include TwitterHelper

  field :user_handle, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0

  validates_length_of :message, maximum: 140

  has_many :records
  def get_user_followers
  	twitter_client.followers(user_handle)
  end

  def blast!
    begin
      get_user_followers.each do |follower|
        sn = follower.screen_name
        puts "Tweeting to: " + sn

        #twitter_client.create_direct_message(follower, message)
        twitter_client.update("@#{ sn } " + message)
        
        self.messages_sent = self.messages_sent + 1

        # create a record
        Record.create!(:twitter_blast_id => id, :record_type => "Twitter handle", :text => follower.screen_name)
      end
      
      save!
    rescue Exception => e 
      puts e.inspect
    end
  end
end