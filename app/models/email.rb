class Email
	include Mongoid::Document
	field :email, type: String
	belongs_to :craig_cram
end