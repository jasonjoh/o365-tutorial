Rails.application.routes.draw do
  get 'mail/index'

  root 'application#home'
  get 'authorize' => 'auth#gettoken'
end
