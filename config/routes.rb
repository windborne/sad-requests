Rails.application.routes.draw do
  get 'sleep' => 'public#sleep'
  get 'wait' => 'public#wait'
  get 'headers' => 'public#show_headers'

  root 'public#up'
end
