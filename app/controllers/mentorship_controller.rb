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
      @rsvp = $client.query("RSVP").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => cookies.signed[:spartaUser][0]
        }))
      end.get.first

      if !@rsvp.blank?
        if @rsvp["attending"] == false
          redirect_to '/dashboard' and return
        end
      elsif @rsvp.blank? && cookies.signed[:spartaUser][1] != "sponsor"
        redirect_to '/dashboard' and return
      end

      @mentor = $client.query("Mentors").tap do |q|
                      q.eq("mentor", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
              end.get.first

      @categories = $client.query("HelpDesk").tap do |q|
                      q.eq("category", "Mentorship")
              end.get.first["subCategory"]

      render layout: false
    end

  end

  def register
    begin
      fields = [ "mentoring", "categories"]

      @mentor = $client.query("Mentors").tap do |q|
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

          cats_to_remove = @mentor["categories"]
          if !cats_to_remove.blank?
            cats = $client.query("Categories").tap do |q|
              q.value_in("name", cats_to_remove)
            end.get

            cats.each do |cat|
              cat["mentors"].delete(cookies.signed[:spartaUser][0])
              cat.save
            end
          end

          @mentor.parse_delete
          @mentor.save
        end
        flash[:popup] = "Decision successfully submitted."
        flash[:sub] = "You may continue to edit your Mentorship status."
        redirect_to '/dashboard' and return
      end



      if !@mentor.blank?
        # this is my favorite segment of code.
        new_cats = mentorship_register_params["categories"]

        cats_to_remove = []
        @mentor["categories"].each do |old_cat|
          if mentorship_register_params["categories"].exclude? old_cat
            cats_to_remove.push(old_cat)
          end
        end

        if !cats_to_remove.blank?
          cats = $client.query("Categories").tap do |q|
            q.value_in("name", cats_to_remove)
          end.get

          cats.each do |cat|
            cat["mentors"].delete(cookies.signed[:spartaUser][0])
            cat.save
          end
        end

        get_cats = $client.query("Categories").tap do |q|
            q.value_in("name", new_cats)
        end.get

        get_cats.each do |a_cat|
          if a_cat["mentors"].exclude? cookies.signed[:spartaUser][0]
            a_cat["mentors"].push(cookies.signed[:spartaUser][0])
            a_cat.save
          end
        end

        @mentor["categories"] = new_cats
        @mentor.save
      else

        get_cats = $client.query("Categories").tap do |q|
            q.value_in("name", mentorship_register_params["categories"])
        end.get

        get_cats.each do |a_cat|
          if a_cat["mentors"].exclude? cookies.signed[:spartaUser][0]
            a_cat["mentors"].push(cookies.signed[:spartaUser][0])
            a_cat.save
          end
        end

        @mentor = $client.object("Mentors")
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
      redirect_to '/mentorship/register'  and return
    end
  end

  private

    def mentorship_register_params
      params.permit(:mentoring, {:categories => []})
    end



end
