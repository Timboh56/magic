class Parameter
  include Mongoid::Document

  field :name, type: String
  field :selector, type: String
  field :include_whitespace, type: Boolean
  
  belongs_to :link

  validates_presence_of :name
end
