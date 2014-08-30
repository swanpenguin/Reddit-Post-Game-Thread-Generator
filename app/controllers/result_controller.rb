require 'espn_box_score'

class ResultController < ApplicationController
  def root
  end
  
  def generate
    @box_score = EspnBoxScore.new(params[:url])
    @post = @box_score.post
    @title = @box_score.title
    render status: 200,
           json: { post: @post,
                   title: @title}
  end
end
