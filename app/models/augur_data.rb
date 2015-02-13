class AugurData
	include Mongoid::Document

	field :data, type: Hash
	belongs_to :person
end