# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
class MailController < ApplicationController

  def index
    token = session[:azure_access_token]
    if token
      # If a token is present in the session, get messages from the inbox
      conn = Faraday.new(:url => 'https://outlook.office365.com') do |faraday|
        # Outputs to the console
        faraday.response :logger
        # Uses the default Net::HTTP adapter
        faraday.adapter  Faraday.default_adapter  
      end
      
      response = conn.get do |request|
        # Get messages from the inbox
        # Sort by DateTimeReceived in descending orderby
        # Get the first 20 results
        request.url '/api/v1.0/Me/Messages?$orderby=DateTimeReceived desc&$top=20'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = "application/json"
      end
      
      @messages = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end

# MIT License: 
 
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# ""Software""), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions: 
 
# The above copyright notice and this permission notice shall be 
# included in all copies or substantial portions of the Software. 
 
# THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.