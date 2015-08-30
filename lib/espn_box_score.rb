require 'open-uri'
require 'nokogiri'
require 'uri'

module EspnBoxScore

  def self.make_box_score(url, subreddit = "")
    if url.include?("nba") 
      EspnBoxScore::Nba.new(url, subreddit)
    elsif url.include?("ncb")
      EspnBoxScore::Ncb.new(url, subreddit)
    elsif url.include?("ncw")
      EspnBoxScore::Ncw.new(url, subreddit)
    else
      nil
    end
  end
end
