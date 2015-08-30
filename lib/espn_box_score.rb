require 'open-uri'
require 'nokogiri'
require 'uri'

class EspnBoxScore
  
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

  RANKED_REGEX = /\A\(\d+\)\z/
  
  def initialize(url, subreddit)
    @url = url
    @subreddit = subreddit.start_with?("/r/") ? subreddit[3..-1] : subreddit
    page = Nokogiri::HTML(open(url))
    @gamehq = page.xpath("//div[@class='gamehq-wrapper']")
    self.away_team = {}
    self.home_team = {}
    make_team(:away, self.away_team)
    make_team(:home, self.home_team)
    make_scoreboard
    make_game_notes
    make_post
    make_title
    make_encoded_url
  end

  def get_game_text(team_index, index)
    @gamehq.xpath("//div[@class='team-info']")[team_index].children.children[index].text
  end
  
  def make_team(type, team)
    index = type == :home ? 1 : 0

    if RANKED_REGEX.match(get_game_text(index, 0))
      team[:ranked] = true 
    end
                        
    if team[:ranked]
      team[:name] = get_game_text(index, 0..2)
      team[:score] = get_game_text(index, 4)
      team[:record] = get_game_text(index, 5)
    else
      team[:name] = get_game_text(index, 0)
      team[:score] = get_game_text(index, 2)
      team[:record] = get_game_text(index, 3)
    end
  end
  
  def make_scoreboard
    @scoreboard = Hash.new
    #includes total
    @scoreboard[:quarters] = @gamehq.xpath("//div[@class='line-score-container']//tr[@class='periods']//td[@class='period' or @class='total']").children.map(&:text)
    
    # [team, score, score, score, score, tot, team, score, score, score, score, tot]
    scores = @gamehq.xpath("//div[@class='line-score-container']//tr[not(@class='periods')]").children.children.map(&:text)
        
    #scores1 -> shift then normal
    #scores2 -> normals
    #scores3 -> take both then shift then placed
    #scores4 -> take, then shift home.
   
    if @away_team[:ranked] && @home_team[:ranked]
      @scoreboard[:away] = scores.take(scores.size/2)
      @scoreboard[:away].shift
      @scoreboard[:home] = scores.drop(scores.size/2)
      @scoreboard[:home].shift
    elsif @away_team[:ranked]
      scores.shift
      @scoreboard[:away] = scores.take(scores.size/2)
      @scoreboard[:home] = scores.drop(scores.size/2)
    elsif @home_team[:ranked]
      @scoreboard[:away] = scores.take(scores.size/2)
      @scoreboard[:home] = scores.drop(scores.size/2)
      @scoreboard[:home].shift
    else
      @scoreboard[:away] = scores.take(scores.size/2)
      @scoreboard[:home] = scores.drop(scores.size/2)
    end
      
  end
  
  def make_game_notes
    @game_notes = Hash.new
    
    if @url.include?("nba") || @url.include?("ncb") || @url.include?("ncw")
      @game_notes[:away] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[0..2].text
      
      @game_notes[:home] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[3..5].text
    else
      @game_notes[:passing] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[0].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[1].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[2].text

      @game_notes[:rushing] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[3].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[4].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[5].text 
    
      @game_notes[:receiving] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[6].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[7].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[8].text
    end
  end
  
  def quarters
    result = "Team"
    scoreboard[:quarters].each do |quarter| 
      result += " | " + quarter.strip
    end
    
    result
  end
  
  #qbq -> quarter by quarter 
  def away_team_qbq
    result = scoreboard[:away].first
    scoreboard[:away][1..-1].each do |score|
      result += " | " + score.strip
    end
    
    result
  end
  
  def home_team_qbq
    result = scoreboard[:home].first
    scoreboard[:home][1..-1].each do |score|
      result += " | " + score.strip
    end
    
    result
  end
  
  def top_performers
    string = ""
    if @url.include?("nba") || @url.include?("ncb") || @url.include?("ncw")
      string << "#{game_notes[:away]}"
      string << "\n\n"
      string << "#{game_notes[:home]}"
    else
      string << "#{game_notes[:passing]}"
      string << "\n\n"
      string << "#{game_notes[:rushing]}"
      string << "\n\n"
      string << "#{game_notes[:receiving]}"
    end
    
    string
  end
  
  def make_post
    @post = "[Box Score provided by ESPN](#{url})
    
**#{away_team[:name]}** #{away_team[:score]} - **#{home_team[:name]}** #{home_team[:score]}

#{quarters}
#{if @url.include? "ncb"
    quarters.size == 4 ? '----|-|-|-' : '----|-|-|-|-'
  else
    quarters.size == 6 ? '----|-|-|-|-|-' : '----|-|-|-|-|-|-'
  end
}
#{away_team_qbq}
#{home_team_qbq}

**Top Performers**

#{top_performers}

**Thoughts**

ಠ_ಠ
┗(｀Дﾟ┗(｀ﾟДﾟ´)┛ﾟД´)┛

[Generator](http://reddit-cfb-postgame.herokuapp.com/) created by /u/swanpenguin
"
  end
  
  def make_title
    @title = "[Post Game Thread] "
    
    if @away_team[:score].to_i == @home_team[:score].to_i
      @title += "#{winner[:name]} and #{loser[:name]} tie, #{winner[:score]}-#{loser[:score]}"
    else
      winner_plural = winner[:name].pluralize == winner[:name] 
      @title += "#{winner[:name]} #{winner_plural ? 'defeat' : 'defeats'} #{loser[:name]}, #{winner[:score]}-#{loser[:score]}"
    end
    
    @title
  end
  
  def winner
    if @away_team[:score].to_i > @home_team[:score].to_i
      @away_team
    else
      @home_team
    end
  end
  
  def loser
    if @away_team == winner
      @home_team
    else
      @away_team
    end
  end
  
  def make_encoded_url
    if !@subreddit.nil? && !@subreddit.empty?
      @encoded_url = "http://www.reddit.com/r/#{@subreddit}/submit?selftext=true&title="
    elsif @url.include?("ncf")
      @encoded_url = "http://www.reddit.com/r/CFB/submit?selftext=true&title="
    elsif @url.include?("nfl")
      @encoded_url = "http://www.reddit.com/r/NFL/submit?selftext=true&title="
    elsif @url.include?("nba")
      @encoded_url = "http://www.reddit.com/r/NBA/submit?selftext=true&title="
    elsif @url.include?("ncb")
      @encoded_url = "http://www.reddit.com/r/CollegeBasketball/submit?selftext=true&title="
    elsif @url.include?("ncw")
      @encoded_url = "http://www.reddit.com/r/NCAAW/submit?selftext=true&title="
    end
    
    
    @encoded_url += URI.encode(@title).gsub("&", "%26")
    @encoded_url += "&text="
    @encoded_url += URI.encode(@post).gsub("&", "%26")
  end
end
