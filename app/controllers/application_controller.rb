class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  JAVASCRIPT_TIME_LIMIT = 30.seconds

  before_filter :prepare_javascript_test

  private
  def prepare_javascript_test
    if (session[:javascript_updated].blank? or Time.now - Time.parse(session[:javascript_updated]) > ApplicationController::JAVASCRIPT_TIME_LIMIT)
      @javascript_active = false
    else
      @javascript_active = true
    end
    
  end

end
