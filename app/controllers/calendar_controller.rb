# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See LICENSE.txt in the project root for license information.
class CalendarController < ApplicationController

  include AuthHelper
  
  def index
    token = get_access_token
    email = session[:user_email]
    if token
      # If a token is present in the session, get events from the calendar
      callback = Proc.new do |r| 
        r.headers['Authorization'] = "Bearer #{token}"
        r.headers['X-AnchorMailbox'] = email
      end

      graph = MicrosoftGraph.new(base_url: 'https://graph.microsoft.com/v1.0',
                                 cached_metadata_file: File.join(MicrosoftGraph::CACHED_METADATA_DIRECTORY, 'metadata_v1.0.xml'),
                                 &callback)

      @events = graph.me.events.order_by('start/dateTime asc')
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end