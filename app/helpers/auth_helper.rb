# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
module AuthHelper

  # App's client ID. Register the app in Azure AD to get this value.
  CLIENT_ID = '<YOUR CLIENT ID>'
  # App's client secret. Register the app in Azure AD to get this value.
  CLIENT_SECRET = '<YOUR CLIENT SECRET>'

  # Generates the login URL for the app.
  def get_login_url
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => "https://login.windows.net",
                                :authorize_url => "/common/oauth2/authorize",
                                :token_url => "/common/oauth2/token")
                                
    login_url = client.auth_code.authorize_url(:redirect_uri => authorize_url)
  end
  
  # Exchanges an authorization code for a token
  def get_token_from_code(auth_code)
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => "https://login.windows.net",
                                :authorize_url => "/common/oauth2/authorize",
                                :token_url => "/common/oauth2/token")
                                
    token = client.auth_code.get_token(auth_code,
                                       :redirect_uri => authorize_url,
                                       :resource => 'https://outlook.office365.com')
                                         
    access_token = token.token
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