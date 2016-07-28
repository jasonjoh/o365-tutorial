class CalendarController < ApplicationController

  include AuthHelper
  
  def index
    token = get_access_token
    email = session[:user_email]
    if token
      # If a token is present in the session, get messages from the inbox
      conn = Faraday.new(:url => 'https://outlook.office.com') do |faraday|
        # Outputs to the console
        faraday.response :logger
        # Uses the default Net::HTTP adapter
        faraday.adapter  Faraday.default_adapter  
      end
      
      response = conn.get do |request|
        # Get events from the calendar
        # Sort by Start in ascending orderby
        # Get the first 10 results
        request.url '/api/v2.0/Me/Events?$orderby=Start/DateTime asc&$select=Subject,Start,End&$top=10'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = "application/json"
        request.headers['X-AnchorMailbox'] = email
      end
      
      @events = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end