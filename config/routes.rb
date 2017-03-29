Rails.application.routes.draw do
  get 'contacts/index'

  get 'calendar/index'

  get 'mail/index'

  root 'home#index'
  get 'authorize' => 'auth#gettoken'
end
