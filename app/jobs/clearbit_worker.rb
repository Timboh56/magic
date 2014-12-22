class ClearbitWorker
  require "mechanize"
  require "pathname"
  require "resque/errors"
  require "clearbit"
  attr_accessor :url, :output_filename
  @queue = :clearbit_queue

  class << self
    def perform(emails)
      emails.each do |email|
        p "Clearbitting #{ email } "
        Clearbit.key = ENV["CLEARBIT_API_KEY"]
        person = Clearbit::Person[email: email, subscribe: true]
        if person && !person.pending?
          puts "Name: #{person.name.fullName}"
        end
      end
    end
  end
end