require 'espn_box_score'

class ResultController < ApplicationController
  def root
  end
  
  def generate
    box_score = EspnBoxScore.new(params[:url], params[:subreddit].strip)
    
    redirect_to box_score.encoded_url 
  end
end
