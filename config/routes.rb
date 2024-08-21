Rails.application.routes.draw do
  get 'sleep' => 'public#sleep'
  get 'wait' => 'public#wait'

  root 'public#up'
end
