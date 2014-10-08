class Parameter
  include Mongoid::Document

  field :name, type: String
  field :selector, type: String
  field :include_whitespace, type: Boolean
  field :reg_exp, type: String
  
  belongs_to :link

  validates_presence_of :name
end
