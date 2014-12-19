class Email
	include Mongoid::Document
	field :email, type: String
	field :name, type: String
	field :password, type: String
	belongs_to :craig_cram
end