class AngelScrape
  include Mongoid::Document
  include AugurHelper
  field :user_index, type: Integer, default: 1

  def run
    angels = AngellistApi.get_users([*user_index..(user_index.to_i + 49)])
    p self.user_index
    angels.each do |angel|
      begin
        twitter_screen_name = angel.twitter_url.present? ? angel.twitter_url.match(/^https?:\/\/(www\.)?twitter\.com\/(#!\/)?(?<name>[^\/]+)(\/\w+)*$/i)["name"] : "" rescue nil
        person = Person.create!(twitter_screen_name: twitter_screen_name, bio: angel.bio, name: angel.name, angellist_info: angel.to_hash)
        p person.inspect

        if twitter_screen_name.present?
          augur_hash = search_with([{ "param_type" => "twitter_handle", "param" => twitter_screen_name }])
          person.augur_info = augur_hash
          person.save!
        end
      rescue Exception => e
        p e.inspect
        p "Name: " + angel.name
      end
    end
    self.user_index += 49
    sleep(4) # limited to 1000 requests in an hour
    run
  rescue Exception => e
    save!
    p "Exception: #{ e.inspect }, stopping.."
  end
end