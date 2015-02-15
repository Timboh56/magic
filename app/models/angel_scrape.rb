class AngelScrape
  include Mongoid::Document
  include AugurHelper
  field :user_index, type: Integer, default: 1

  def run(limit = 50000)
    angels = AngellistApi.get_users([*user_index..(user_index.to_i + 49)])
    p self.user_index
    angels.each do |angel|
      begin
        twitter_screen_name = angel.twitter_url.present? ? angel.twitter_url.match(/^https?:\/\/(www\.)?twitter\.com\/(#!\/)?(?<name>[^\/]+)(\/\w+)*$/i)["name"] : "" rescue nil
        person = Person.create!(investor: angel.investor, twitter_screen_name: twitter_screen_name, bio: angel.bio, name: angel.name, angellist_info: angel.to_hash)
        p person.inspect
      rescue Exception => e
        p e.inspect
        p "Name: " + angel.name
      end
    end
    self.user_index += 50
    sleep(4) # limited to 1000 requests in an hour
    run
  rescue Exception => e
    save!
    p "Exception: #{ e.inspect }, stopping.."
  end

  def self.user_search(name)
    AngellistApi.user_search(name.gsub(" ","-").lowercase)
  end
end