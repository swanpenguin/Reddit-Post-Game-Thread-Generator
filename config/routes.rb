Rails.application.routes.draw do
  
  get '/result/generate', to: 'result#generate'
  
  root to: "result#home"
end
