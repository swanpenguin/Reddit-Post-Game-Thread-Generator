require 'open-uri'
require 'nokogiri'

class EspnBoxScore
  
  attr_reader :gamehq, :url, :away_team, :home_team, :scoreboard, :game_notes, :post, :title
  RANKED_REGEX = /\A\(\d+\)\z/
  
  def initialize(url)
    @url = url
    page = Nokogiri::HTML(open(url))
    @gamehq = page.xpath("//div[@class='gamehq-wrapper']")
    make_away_team
    make_home_team
    make_scoreboard
    make_game_notes
    make_post
    make_title
  end
  
  def make_away_team
    @away_team = Hash.new
    @away_team[:ranked] = true if RANKED_REGEX.match(@gamehq.xpath("//div[@class='team-info']").first.
                        children.children[0].text)
                        
    if @away_team[:ranked]
      @away_team[:name] = @gamehq.xpath("//div[@class='team-info']").first.
                        children.children[0..2].text
                      
      @away_team[:score] = @gamehq.xpath("//div[@class='team-info']").first.
                         children.children[4].text
                      
      @away_team[:record] = @gamehq.xpath("//div[@class='team-info']").first.
                          children.children[5].text
    else
      @away_team[:name] = @gamehq.xpath("//div[@class='team-info']").first.
                        children.children[0].text
                      
      @away_team[:score] = @gamehq.xpath("//div[@class='team-info']").first.
                         children.children[2].text
                      
      @away_team[:record] = @gamehq.xpath("//div[@class='team-info']").first.
                          children.children[3].text
    end

  end
  
  def make_home_team
    @home_team = Hash.new
    @home_team[:ranked] = true if RANKED_REGEX.match(@gamehq.xpath("//div[@class='team-info']").last.
                        children.children[0].text)
                        
    if @home_team[:ranked]
      @home_team[:name] = @gamehq.xpath("//div[@class='team-info']").last.
                        children.children[0..2].text
                      
      @home_team[:score] = @gamehq.xpath("//div[@class='team-info']").last.
                         children.children[4].text
                      
      @home_team[:record] = @gamehq.xpath("//div[@class='team-info']").last.
                          children.children[5].text
    else
      @home_team[:name] = @gamehq.xpath("//div[@class='team-info']").last.
                        children.children[0].text
                      
      @home_team[:score] = @gamehq.xpath("//div[@class='team-info']").last.
                         children.children[2].text
                      
      @home_team[:record] = @gamehq.xpath("//div[@class='team-info']").last.
                          children.children[3].text
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
      @schoreboard[:home] = scores.drop(scores.size/2)
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
    @game_notes[:passing] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[0].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[1].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[2].text

    @game_notes[:rushing] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[3].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[4].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[5].text 
    
    @game_notes[:receiving] = gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[6].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[7].text + gamehq.xpath("//div[@class='game-notes']//p[not(@class='heading')]").children[8].text
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
  
  def make_post
    @post = "[Box Score provided by ESPN](#{url})
    
**#{away_team[:name]}** #{away_team[:score]} - **#{home_team[:name]}** #{home_team[:score]}

#{quarters}
#{quarters.size == 6 ? '----|-|-|-|-|-' : '----|-|-|-|-|-|-'}
#{away_team_qbq}
#{home_team_qbq}

**Top Performers**

#{game_notes[:passing]}

#{game_notes[:rushing]}

#{game_notes[:receiving]}

**Thoughts**

*please substitute this for 2-4 thoughts you had during this game.*
    
    
"
  end
  
  def make_title
    @title = "[Post-Game Thread] "
    @title += "#{winner[:name]} "
    @title += "defeats "
    @title += "#{loser[:name]}, "
    @title += "#{winner[:score]}-#{loser[:score]}"
    
    @title
  end
  
  def winner
    if @away_team[:score] > @home_team[:score]
      @away_team
    else
      @home_team
    end
  end
  
  def loser
    if @away_team[:name] == winner
      @home_team
    else
      @away_team
    end
  end
end