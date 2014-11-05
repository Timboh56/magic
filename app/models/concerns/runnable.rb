module Runnable
  extend ActiveSupport::Concern
  
  included do
    field :status, type: String
    field :name, type: String
    has_many :records, dependent: :destroy
  end

  def records_count
  	records.count
  end
end