class ApiController < ApplicationController
  require 'parse_config'
  
  def school
    # Collects all the applications for that school
    @apps = Parse::Query.new("Application").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                    end.get

    @apps += Parse::Query.new("Application").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                      q.skip = 1000
                    end.get

    @response = {}

    @school_dates = []
    @apps.each do |app|
    	@school_dates.push(app["createdAt"])
    end

    @response["timestamps"] = @school_dates
    
    respond_to do |format|
      format.html { render json: @response}
      format.json { render json: @response}
 	  end

  end

  private

  def school_params
  	params.permit(:school)
  end 
end
