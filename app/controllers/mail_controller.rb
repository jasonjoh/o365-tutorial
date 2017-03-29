# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See LICENSE.txt in the project root for license information.
class MailController < ApplicationController

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
        # Get messages from the inbox
        # Sort by ReceivedDateTime in descending orderby
        # Get the first 20 results
        request.url '/api/v2.0/Me/MailFolders/Inbox/Messages?$orderby=ReceivedDateTime desc&$select=ReceivedDateTime,Subject,From&$top=20'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = 'application/json'
        request.headers['X-AnchorMailbox'] = email
      end
      
      @messages = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end