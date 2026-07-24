module Dashboard
  class BaseController < ApplicationController
    before_action :authenticate_user!
    layout "dashboard"
  end
end
