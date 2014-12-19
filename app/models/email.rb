class Email
	include Mongoid::Document
	field :email, type: String
	field :name, type: String
	field :password, type: String
	field :used, type: Boolean, default: false
	belongs_to :craig_cram

	scope :unused, lambda { where(used: false) }
end