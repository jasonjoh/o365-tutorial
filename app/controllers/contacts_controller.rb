# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See LICENSE.txt in the project root for license information.
class ContactsController < ApplicationController

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
        # Get contacts from the default contacts folder
        # Sort by GivenName in ascending orderby
        # Get the first 10 results
        request.url '/api/v2.0/Me/Contacts?$orderby=GivenName asc&$select=GivenName,Surname,EmailAddresses&$top=10'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = "application/json"
        request.headers['X-AnchorMailbox'] = email
      end
      
      @contacts = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end