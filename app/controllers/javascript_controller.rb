class JavascriptController < ApplicationController
  def confirm
    session[:javascript_updated] = Time.now
    if !js_params["precheck"].blank?
    	if !session[:return_to].blank?
    		redirect_to session.delete(:return_to)
    	else 
    		redirect_to '/'
    	end
    end
  end

  def jscheck
  	render layout: false
  end


  private

    def js_params
      params.permit(:precheck)
    end

end
