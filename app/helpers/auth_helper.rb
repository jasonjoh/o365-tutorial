# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
module AuthHelper

  # App's client ID. Register the app in Application Registration Portal to get this value.
  CLIENT_ID = '<YOUR APP ID HERE>'
  # App's client secret. Register the app in Application Registration Portal to get this value.
  CLIENT_SECRET = '<YOUR APP PASSWORD HERE>'
  
  # Scopes required by the app
  SCOPES = [ 'openid',
             'profile',
             'https://outlook.office.com/mail.read',
             'https://outlook.office.com/calendars.read',
             'https://outlook.office.com/contacts.read' ]

  # Generates the login URL for the app.
  def get_login_url
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => 'https://login.microsoftonline.com',
                                :authorize_url => '/common/oauth2/v2.0/authorize',
                                :token_url => '/common/oauth2/v2.0/token')
                                
    login_url = client.auth_code.authorize_url(:redirect_uri => authorize_url, :scope => SCOPES.join(' '))
  end
  
  # Exchanges an authorization code for a token
  def get_token_from_code(auth_code)
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => 'https://login.microsoftonline.com',
                                :authorize_url => '/common/oauth2/v2.0/authorize',
                                :token_url => '/common/oauth2/v2.0/token')
                                
    token = client.auth_code.get_token(auth_code,
                                       :redirect_uri => authorize_url,
                                       :scope => SCOPES.join(' '))
  end
  
  # Parses an ID token and returns the user's email
  def get_email_from_id_token(id_token)
    
    # JWT is in three parts, separated by a '.'
    token_parts = id_token.split('.')
    # Token content is in the second part
    encoded_token = token_parts[1]
    
    # It's base64, but may not be padded
    # Fix padding so Base64 module can decode
    leftovers = token_parts[1].length.modulo(4)
    if leftovers == 2
      encoded_token += '=='
    elsif leftovers == 3
      encoded_token += '='
    end
    
    # Base64 decode (urlsafe version)
    decoded_token = Base64.urlsafe_decode64(encoded_token)
    
    # Load into a JSON object
    jwt = JSON.parse(decoded_token)
    
    # Email is in the 'preferred_username' field
    email = jwt['preferred_username']
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
