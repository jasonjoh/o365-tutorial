# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See LICENSE.txt in the project root for license information.
class ContactsController < ApplicationController

  include AuthHelper
  
  def index
    token = get_access_token
    if token
      # If a token is present in the session, get contacts
      callback = Proc.new do |r| 
        r.headers['Authorization'] = "Bearer #{token}"
      end

      graph = MicrosoftGraph.new(base_url: 'https://graph.microsoft.com/v1.0',
                                 cached_metadata_file: File.join(MicrosoftGraph::CACHED_METADATA_DIRECTORY, 'metadata_v1.0.xml'),
                                 &callback)

      @contacts = graph.me.contacts.order_by('givenName asc')
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end