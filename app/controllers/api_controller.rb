class ApiController < ApplicationController
  require 'parse_config'
  require 'json'

  def school
    # Collects all the applications for that school
    @apps = $client.query("Application").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                    end.get

    @apps += $client.query("Application").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                      q.skip = 1000
                    end.get

    @response = {}

    @school_dates = []
    @apps.each do |app|
    	@school_dates.push(app["createdAt"])
    end

    @rsvps = $client.query("RSVP").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                    end.get

    @rsvps += $client.query("RSVP").tap do |q|
    				          q.eq("university", school_params[:school])
                      q.limit = 1000
                      q.skip = 1000
                    end.get

    pp @rsvps

    @rsvp_dates = []
    @rsvps.each do |rsvp|
    	@rsvp_dates.push(rsvp["createdAt"])
    end

    @response["applicant-timestamps"] = @school_dates
    @response["applicant-total"] = @apps.length
    @response["rsvp-timestamps"] = @rsvp_dates
    @response["rsvp-total"] = @rsvps.length

    respond_to do |format|
      format.html { render json: @response.to_json}
      format.json { render json: @response.to_json}
 	  end

  end

  private

  def school_params
  	params.permit(:school)
  end
end
