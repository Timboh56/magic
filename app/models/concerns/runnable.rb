module Runnable
  extend ActiveSupport::Concern
  
  included do
    field :status, :type => String
    has_many :records
  end
end