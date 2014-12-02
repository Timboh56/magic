class UserWorker
	require "resque/errors"
  # extend RetriedJob
  @queue = :user_queue

  class << self

  	def perform(id, action)
  		puts id.inspect
  		@user = User.find(id["$oid"])
  		send(action)
  	end

  	def unfollow_following_not_followers
  		@user.unfollow_following_not_followers
  	end
  end
end