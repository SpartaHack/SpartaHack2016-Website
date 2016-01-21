class MentorshipController < ApplicationController
  
  def registration
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign in."
      session[:return_to] = '/mentorship/register'
      redirect_to '/login'
    elsif !@javascript_active
      session[:return_to] = '/mentorship/register'
      redirect_to '/jscheck'
    else
      @rsvp = Parse::Query.new("RSVP").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => cookies.signed[:spartaUser][0]
        }))
      end.get.first

      if @rsvp.blank? || !@rsvp["attending"]
        redirect_to '/dashboard' and return
      end

      @mentor = Parse::Query.new("Mentors").tap do |q|
                      q.eq("mentor", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
              end.get.first

      @categories = Parse::Query.new("HelpDesk").tap do |q|
                      q.eq("category", "Mentorship")
              end.get.first["subCategory"]

      render layout: false
    end

  end

  def register
    begin
      fields = [ "mentoring", "categories"]

      @mentor = Parse::Query.new("Mentors").tap do |q|
                      q.eq("mentor", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
            end.get.first

      if !mentorship_register_params["mentoring"].blank? && mentorship_register_params["mentoring"] == "true"
        if mentorship_register_params["categories"].blank?

          flash[:popup] = "You must fill in all the required fields."
          redirect_to '/mentorship/register'  and return
        end
      elsif !mentorship_register_params["mentoring"].blank? && mentorship_register_params["mentoring"] == "false"
        if !@mentor.blank?
          @mentor.parse_delete
          @mentor.save
        end
        redirect_to '/dashboard'
      end



      if !@mentor.blank?
        @mentor["categories"] = mentorship_register_params["categories"]
        @mentor.save
      else
        @mentor = Parse::Object.new("Mentors")
        @mentor["categories"] = mentorship_register_params["categories"]
        @mentor["mentor"] = Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      })
        @mentor.save
      end

      flash[:popup] = "Decision successfully submitted."
      flash[:sub] = "You may continue to edit your Mentorship status."
      redirect_to '/mentorship/register'  and return
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      puts e.message
      redirect_to '/mentorship/register'
    end
  end

  private

    def mentorship_register_params
      params.permit(:mentoring, {:categories => []})     
    end



end
