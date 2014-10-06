class Proxy
  include Mongoid::Document

  field :ip, type: String
  field :port, type: Integer
  field :working, type: Boolean

  validates_uniqueness_of :ip
end
