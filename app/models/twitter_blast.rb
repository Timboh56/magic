class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
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

  def handles_array
    twitter_handles.present? ? twitter_handles.split(",") : nil
  end

  def handle_records_count
    records.present? ? records.handles.count : 0
  end
end