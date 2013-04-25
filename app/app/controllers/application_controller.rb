class ApplicationController < ActionController::Base
  include QuickScript::Interaction
  protect_from_forgery

end
