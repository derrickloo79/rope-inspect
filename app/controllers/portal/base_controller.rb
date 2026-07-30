module Portal
  class BaseController < ApplicationController
    before_action :authenticate_fsp!
    layout "portal"
  end
end
