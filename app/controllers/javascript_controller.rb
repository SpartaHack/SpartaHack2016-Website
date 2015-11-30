class JavascriptController < ApplicationController
  def confirm
    session[:javascript_updated] = Time.now
  end

  def noJS
  	render layout: false
  end

end
