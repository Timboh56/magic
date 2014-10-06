class Parameter
  include Mongoid::Document

  field :name, type: String
  field :selector, type: String
  field :param_type, type: String # "Link" or "Data"
  belongs_to :scrape
end
