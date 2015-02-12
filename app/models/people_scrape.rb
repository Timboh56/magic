class PeopleScrape
  include Mongoid::Document
  include CrunchbaseHelper
  include CSVHelper

  field :keywords, type: String
  field :min_follower_count, type: Integer, default: 0
  field :max_follower_count, type: Integer, default: 10000
  field :page_index, type: Integer, default: 1
  belongs_to :user
  has_many :people

  def enqueue
    Resque.enqueue(PeopleScrapeWorker, id, "run")
  end

  def people_csv
    collection_to_csv(people)
  end

  def scrape_organization_members(organization_name)
    save_team_members(organization_name).each do |team_member|
     search_twitter("#{ organization_name } #{ team_member }")
    end
  end

  def search_twitter(keyword_params, page_index = 1)
    search_results = user.twitter_client.user_search(keyword_params, { page: page_index })
  end

  def scrape_twitter(keyword_params, index = 1)

    # 180 requests every 15 minutes
    while(index < 180) do
      p index
      search_results = search_twitter(keyword_params, index)

      # filter search results by min and max follower count
      search_results.each do |twitter_user|
        begin
          if twitter_user.followers_count > min_follower_count && twitter_user.followers_count < max_follower_count
            p twitter_user.inspect
            unless Person.where(name: twitter_user.name).exists?
              person = Person.create!(people_scrape_id: id, name: twitter_user.name, twitter_info: twitter_user.to_hash)
            else
              p "Person with name #{ twitter_user.name } already exists, skipping.."
            end
          end
        rescue Exception => e
          p e.inspect
        end
      end
      index += 1
      sleep(10) # wait 5 seconds for next batch
    end
    index
  rescue Exception => e
    p "Error: #{ e.inspect }"
    index
  end

  # runs daily
  def run
    index = scrape_twitter(keywords, page_index)
    self.page_index = index
    save!
    # call augur.io
  end
end