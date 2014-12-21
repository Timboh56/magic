class Email
	include Mongoid::Document
	field :email, type: String
	field :name, type: String
	field :password, type: String
	field :used, type: Boolean, default: false
	belongs_to :craig_cram

	scope :unused, lambda { where(used: false) }


  def self.open_emails_csv
    p "Opening proxies csv"

    Dir["emails/*.csv"].each do |csv_file_path|

      p csv_file_path
      CSV.foreach(csv_file_path) do |row|
        email = row[5]
        password = row[6]
        Email.create!(email: email, password: password) unless Email.where(email: email, password: password).exists?
      end
  	end
  end
end