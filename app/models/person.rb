class Person
	include Mongoid::Document

	field :name, type: String
	field :email, type: String
	field :phone, type: String
	field :google_id, type: String
	field :available, type: Boolean, default: true
	field :clearbit
	field :person_type, type: String # tutor
	validates_uniqueness_of :google_id
end