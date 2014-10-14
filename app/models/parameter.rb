class Parameter
  include Mongoid::Document

  field :name, type: String
  field :selector, type: String
  field :include_whitespace, type: Boolean
  field :text_to_remove, type: String
  
  belongs_to :data_set

  validates_presence_of :name
end
