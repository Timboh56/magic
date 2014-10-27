class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  field :name, :type => String
  field :status, :type => String
  field :message, :type => String
  field :messages_sent, :type => Integer, :default => 0
  field :twitter_handles, :type => String
  field :blast_type, :type => String # followers or handles
  validates_length_of :message, maximum: 140

  has_many :records, :dependent => :destroy
  has_many :handle_lists

  after_create :create_handle_list

  def blast!(user, limit = nil)
    Resque.enqueue(TwitterBlastWorker, id, user.id, limit)
  end

  def handles_array
    twitter_handles.present? ? twitter_handles.split(",") : nil
  end

  def handle_records_count
    records.present? ? records.handles.count : 0
  end

  def create_handle_list
    handle_list = HandleList.new
    handle_list.name = name
    handle_list.handles = records.handles
    handle_list.twitter_blast_id = id
  end
end