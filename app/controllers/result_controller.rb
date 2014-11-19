require 'espn_box_score'

class ResultController < ApplicationController
  def root
  end
  
  def generate
    @box_score = EspnBoxScore.new(params[:url])
    @post = @box_score.post
    @title = @box_score.title
    @encoded_url = @box_score.encoded_url
    
    # render status: 200,
#            json: { post: @post,
#                    title: @title,
#                    encoded_url: @encoded_url }

    redirect_to @encoded_url 
  end
end
