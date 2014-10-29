class TwitterBlast
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  field :name, type: String
  field :status, type: String
  field :message, type: String
  field :messages_sent, type: Integer, default: 0
  field :twitter_handles, type: String
  field :blast_type, type: String # followers or handles
  field :limit, type: Integer, default: 5000
  field :handles_type, type: String, default: "textarea" # textarea or list
  validates_length_of :message, maximum: 140

  has_many :records, :dependent => :destroy
  belongs_to :handle_list

  before_create :create_handle_list

  def handles_stringified
    handle_list.handles.take(limit).map! { |h| h.text }
  end

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
    if handles_type == "list" && handle_list_id.nil?
      handle_list = HandleList.new
      handle_list.name = name
      handle_list.handles = records.handles
      handle_list.save!
      handle_list_id = handle_list.id
    end
  end
end