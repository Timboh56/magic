class Person
	include Mongoid::Document

	field :name, type: String
	field :email, type: String
	field :google_id, type: String
	field :available, type: Boolean, default: true
	field :clearbit
end