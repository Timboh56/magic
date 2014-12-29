class Email
	include Mongoid::Document
	field :email, type: String
	field :name, type: String
	field :password, type: String
	field :used, type: Boolean, default: false
  field :email_type, type: String # Dummy, Client
  field :body
	belongs_to :craig_cram

	scope :unused, lambda { where(used: false) }

  validates_format_of :email, :with => /\A(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})\z/i
  validates_presence_of :email
  validate :check_name_and_body

  def check_name_and_body
    if email_type == "Client"
      errors.add :body, "must not be empty" if !body.present?
      errors.add :name, "must not be empty" if !name.present?
    end
  end

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