class Person
	include Mongoid::Document

	field :email, type: String
	field :clearbit
end