class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :user_handle, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0
  field :twitter_handles, :type => String
  field :blast_type, :type => String # followers or handles

  validates_length_of :message, maximum: 140

  has_many :records, :dependent => :destroy

  def blast!(user)
    Resque.enqueue(TwitterBlastWorker, id, user.id)
  end
end