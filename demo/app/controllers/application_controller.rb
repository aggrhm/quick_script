class ApplicationController < ActionController::Base
  include QuickScript::Interaction
  protect_from_forgery

  def home
    render :text => '', :layout => 'application'
  end
end
