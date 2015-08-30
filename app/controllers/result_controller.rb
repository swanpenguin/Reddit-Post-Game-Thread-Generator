require 'espn_box_score'

class ResultController < ApplicationController
  def home
  end
  
  def generate
    box_score = EspnBoxScore::make_box_score(params[:game][:espn_url], params[:game][:subreddit].strip)
    
    redirect_to box_score.encoded_url 
  end
end
