module EspnBoxScore
  class Base

    RANKED_REGEX = /\A\(\d+\)\z/

    attr_accessor :gamehq, 
                  :url, 
                  :subreddit, 
                  :away_team, 
                  :home_team, 
                  :scoreboard, 
                  :game_notes, 
                  :post, 
                  :title, 
                  :encoded_url

  end
end
