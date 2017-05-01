# Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See LICENSE.txt in the project root for license information.
class HomeController < ApplicationController
  include AuthHelper
  
  def index
    # Display the login link.
    @login_url = get_login_url
  end
end
