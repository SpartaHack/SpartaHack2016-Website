class UsersController < ApplicationController
	require 'parse_config'
  require 'monkey_patch'
  require "open-uri"
  require 'json'

	def sorry
		render layout: false
	end

  def register
    if cookies.signed[:spartaUser]
      redirect_to '/login' and return
		else
			if register_params["t"].blank?
				redirect_to "/sorry" and return
			else
				token = Parse::Query.new("AppCode").tap do |q|
												q.eq("code", register_params["t"])
												q.eq("used", false)
											end.get.first

				if !token.blank?
					token["used"] = true;
					token.save

					render layout: false
				else
					redirect_to "/sorry" and return
				end
			end
    end

  end

  #create a user and redirect them to application process
  def create
    if user_app_params['email'].blank? || user_app_params['password'].blank? || user_app_params['password_confirmation'].blank? ||
      user_app_params["firstName"].blank? || user_app_params["lastName"].blank? || user_app_params["gender"].blank? ||
        user_app_params["birthday"].blank?|| user_app_params["birthmonth"].blank? || user_app_params["birthyear"].blank? ||
        user_app_params["universityStudent"].blank? || user_app_params["mlh"].blank?
        flash[:popup] = "You must fill in all the required fields."
        flash[:params] = user_app_params
        redirect_to '/register' and return
    elsif user_app_params['password'] != user_app_params['password_confirmation']
      flash[:popup] = "Passwords do not match"
      flash[:params] = user_app_params
      redirect_to '/register' and return

    else
      if user_app_params['email'].downcase !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        flash[:popup] = "You must use a valid email."
        flash[:params] = user_app_params
        redirect_to '/register' and return
      end
      begin
        apply = Parse::User.new({
          :username => user_app_params['email'].downcase,
					:firstName => user_app_params["firstName"].capitalize,
					:lastName => user_app_params["lastName"].capitalize,
          :email => user_app_params['email'].downcase,
          :password => user_app_params['password'],
          :role => "attendee"
        })
        response = apply.save
        cookies.permanent.signed[:spartaUser] = { value: [response["objectId"], "attendee"] }
      rescue Parse::ParseProtocolError => e
        if e.to_s.split(":").first == '202' || e.to_s.split(":").first == "203"
          flash[:popup] = "Email is taken"
          flash[:params] = user_app_params
          redirect_to '/register' and return
        else
          redirect_to "/outage" and return
        end

      end

      save()
    end
  end

  def save

    if user_app_params["firstName"].blank? || user_app_params["lastName"].blank? || user_app_params["gender"].blank? ||
        user_app_params["birthday"].blank?|| user_app_params["birthmonth"].blank? || user_app_params["birthyear"].blank? ||
        user_app_params["universityStudent"].blank? || user_app_params["mlh"].blank?
      flash[:popup] = "You must fill in all the required fields."
      flash[:params] = user_app_params
      redirect_to '/application'  and return
    end

    begin
      fields = ["gender", "birthday", "birthmonth", "birthyear",
                                "major", "gradeLevel", "whyAttend", "hackathons",
                                "github", "linkedIn", "website", "devPost", "coolLink",
                                "universityStudent", "mlh"]

      application = Parse::Query.new("Application").tap do |q|
                      q.eq("user", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
                    end.get.first
      if !application
        flash[:popup] = "Application successfully submitted."
        flash[:sub] = "You may continue to edit your application."
        application = Parse::Object.new("Application")
      else
        flash[:popup] = "Application updated."
        flash[:sub] = "You may continue to edit your application."
      end

      fields.each do |field|
        if field == "universityStudent" && user_app_params["universityStudent"].to_bool == true
          application["universityStudent"] = "true"
          if user_app_params["otherUniversityConfirm"].to_bool == true
            application["otherUniversityConfirm"] = "true"
            application["otherUniversity"] = user_app_params["otherUniversity"]
            application["university"] = nil
          else
            application["otherUniversityConfirm"] = "false"
            application["university"] = user_app_params["university"]
            application["otherUniversity"] = nil
          end
        elsif field == "universityStudent" && user_app_params["universityStudent"].to_bool == false
          application["universityStudent"] = "false"
          application["otherUniversityConfirm"] = "false"
          application["university"] = nil
          application["otherUniversity"] = nil
        else
          application[field] = user_app_params[field]
        end

      end
      response = application.save

      application = Parse::Query.new("Application").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      application["user"] = user.pointer
      application.save

      redirect_to '/application'  and return
    rescue Parse::ParseProtocolError => e
      flash[:popup] =  e.message
      flash[:params] = user_app_params
      redirect_to "/outage" and return
    end

  end

  def application
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign up to create an application."
      redirect_to '/register'
    elsif !@javascript_active
      session[:return_to] = '/application'
      redirect_to '/jscheck'
    else
      begin
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      rescue
        redirect_to "/outage" and return
      end

      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
          q.include = "user"
        end.get.first

        if @application
          if @application["university"].blank? && @application["otherUniversity"].blank?
            @application["universityStudent"] = false
          else
            @application["universityStudent"] = true
          end
        end

        render layout: false
      rescue Parse::ParseProtocolError => e
        flash[:error] = e.message
        redirect_to '/login'
      end
    end
  end



  def login
    if cookies.signed[:spartaUser]
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
        end.get.first

        if @application
          redirect_to '/dashboard' and return
        else
          redirect_to '/application' and return
        end

      rescue Parse::ParseProtocolError => e
        redirect_to "/outage" and return
      end

    elsif !@javascript_active
      session[:return_to] ||= '/login'
      redirect_to '/jscheck'
    else
      render layout: false
    end
  end

  def logout
    cookies.delete :spartaUser
    redirect_to "/"
  end

  # authenticate user and redirect them to their application
  def auth
  	begin
			login = Parse::User.authenticate(user_login_params['email'].downcase,user_login_params['password'])
      if login["role"] == "admin" || login["role"] == "sponsorship" || login["role"] == "statistics"
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], login["role"]] }
			  redirect_to '/admin' and return
      else
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], "attendee"] }
        begin
          @application = Parse::Query.new("Application").tap do |q|
            q.eq("user", Parse::Pointer.new({
              "className" => "_User",
              "objectId"  => login["objectId"]
            }))
          end.get.first

          if !session[:return_to].blank?
            redirect_to session.delete(:return_to)
          elsif @application
            redirect_to '/dashboard' and return
          else
            redirect_to '/application' and return
          end

        rescue Parse::ParseProtocolError => e

        end

      end
		rescue Parse::ParseProtocolError => e
			if e.to_s.split(":").first == '101'
		  	flash[:error] = "Invalid credentials."
		  	redirect_to '/login'
		  end
		end

  end

  def dashboard
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign in."
      session[:return_to] = '/dashboard'
      redirect_to '/login'
    elsif !@javascript_active
      session[:return_to] = '/dashboard'
      redirect_to '/jscheck'
    else
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
          q.include = "user"
        end.get.first

        if !@application
          redirect_to '/application' and return
        end

        @rsvp = Parse::Query.new("RSVP").tap do |q|
                        q.eq("user", Parse::Pointer.new({
                          "className" => "_User",
                          "objectId"  => cookies.signed[:spartaUser][0]
                        }))
        end.get.first


        begin
          if !@application['university'].blank?
            @travel = Parse::Query.new("Travel").tap do |q|
                          q.eq("university", @application['university'])
                  end.get.first
          end
          data_bus_1 = JSON.parse(URI.parse("https://www.eventbriteapi.com/v3/events/"+ENV["BUS_1"]+"/ticket_classes/?token="+ENV["EVENTBRITE_AUTH"]).read)
          if data_bus_1["ticket_classes"][0]["on_sale_status"] == "SOLD_OUT"
            @bus_1 = 0
          else
            @bus_1 = data_bus_1["ticket_classes"][0]["quantity_total"] - data_bus_1["ticket_classes"][0]["quantity_sold"]
          end

          data_bus_2 = JSON.parse(URI.parse("https://www.eventbriteapi.com/v3/events/"+ENV["BUS_2"]+"/ticket_classes/?token="+ENV["EVENTBRITE_AUTH"]).read)
          if data_bus_1["ticket_classes"][0]["on_sale_status"] == "SOLD_OUT"
            @bus_2 = 0
          else
            @bus_2 = data_bus_2["ticket_classes"][0]["quantity_total"] - data_bus_2["ticket_classes"][0]["quantity_sold"]
          end

          data_bus_3 = JSON.parse(URI.parse("https://www.eventbriteapi.com/v3/events/"+ENV["BUS_3"]+"/ticket_classes/?token="+ENV["EVENTBRITE_AUTH"]).read)
          if data_bus_3["ticket_classes"][0]["on_sale_status"] == "SOLD_OUT"
            @bus_2 = 0
          else
            @bus_3 = data_bus_3["ticket_classes"][0]["quantity_total"] - data_bus_3["ticket_classes"][0]["quantity_sold"]
          end
        rescue
          @bus_1 = nil
          @bus_2 = nil
          @bus_3 = nil
        end

        if !@rsvp.blank?
          if !@application['birthyear'].blank?
            curr_bday = Time.zone.local(@application['birthyear'].to_i, Date::MONTHNAMES.index(@application['birthmonth']), @application['birthday'].to_i, 0, 0)
            if age(curr_bday, Date.new(2016, 2, 26)) < 18
              @minor = true
            else
              @minor = false
            end
          end

          @travel = Parse::Query.new("Travel").tap do |q|
                        q.eq("university", @rsvp['university'])
                end.get.first

          if @travel.blank?
            @travel = Parse::Query.new("Travel").tap do |q|
                          q.eq("university", @application['university'])
                  end.get.first
          end

        end

        render layout: false
      rescue
        redirect_to "/outage" and return
      end
    end
  end

  def rsvp
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign in."
      session[:return_to] = '/rsvp'
      redirect_to '/login'
    elsif !@javascript_active
      session[:return_to] = '/rsvp'
      redirect_to '/jscheck'
    else
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
        end.get.first

        if !@application
          redirect_to '/application' and return
        else
          if @application["status"] != "Accepted" || @application["status"] == "Accepted" && @application["exception"] != true
            redirect_to '/dashboard' and return
          end
        end

        @rsvp = Parse::Query.new("RSVP").tap do |q|
                        q.eq("user", Parse::Pointer.new({
                          "className" => "_User",
                          "objectId"  => cookies.signed[:spartaUser][0]
                        }))
                end.get.first

        render layout: false
      rescue
        redirect_to "/outage" and return
      end
    end
  end

  def saversvp
    begin
      fields = [ "university", "restrictions", "otherRestrictions", "tshirt"]

      rsvp = Parse::Query.new("RSVP").tap do |q|
                      q.eq("user", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
            end.get.first

      @app = Parse::Query.new("Application").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => cookies.signed[:spartaUser][0]
        }))
      end.get.first

      @mentor = Parse::Query.new("Mentors").tap do |q|
                      q.eq("mentor", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
              end.get.first

      if !user_rsvp_params["attending"].blank? && user_rsvp_params["attending"] == "true"
        if user_rsvp_params["university"].blank? || user_rsvp_params["restrictions"].blank? ||
          user_rsvp_params["tshirt"].blank?

          flash[:popup] = "You must fill in all the required fields."
          redirect_to '/rsvp'  and return
        end
      elsif !user_rsvp_params["attending"].blank? && user_rsvp_params["attending"] == "false"
        if !rsvp
          flash[:popup] = "RSVP successfully submitted."
          flash[:sub] = "You may continue to edit your RSVP."
          rsvp = Parse::Object.new("RSVP")
        else
          flash[:popup] = "RSVP updated."
          flash[:sub] = "You may continue to edit your RSVP."
        end

        fields.each do |field|
          rsvp[field] = nil
        end

        rsvp['attending'] = false
        rsvp['resume'] = nil

        if !@mentor.blank?

          cats_to_remove = @mentor["categories"]
          if !cats_to_remove.blank?
            cats = Parse::Query.new("Categories").tap do |q|
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

        response = rsvp.save

        rsvp = Parse::Query.new("RSVP").eq("objectId", response["objectId"]).get.first
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
        rsvp["user"] = user.pointer

        if rsvp["application"].blank?
          rsvp["application"] = @app.pointer
        end

        rsvp.save

        redirect_to '/rsvp'  and return
      end

      if !rsvp
        if user_rsvp_params["resume"].blank?
          flash[:popup] = "You must fill in all the required fields."
          redirect_to '/rsvp'  and return
        end

        flash[:popup] = "RSVP successfully submitted."
        flash[:sub] = "You may continue to edit your RSVP."
        rsvp = Parse::Object.new("RSVP")
      else
        flash[:popup] = "RSVP updated."
        flash[:sub] = "You may continue to edit your RSVP."
      end

      fields.each do |field|
        rsvp[field] = user_rsvp_params[field]
      end
      rsvp['attending'] = true

      if !user_rsvp_params['resume'].blank?
        #save resume to parse
        begin
          resume = user_rsvp_params['resume']
          parse_resume = Parse::File.new({
            :body => resume.read,
            :local_filename => "resume.pdf" ,
            :content_type => resume.content_type,
            :content_length => resume.tempfile().size().to_s
          })
          parse_resume.save

					rsvp['resumeDownloaded'] = false
          rsvp['resume'] = parse_resume
        rescue
          flash[:popup] = "RSVP not saved."
          flash[:sub] = "Please contact us."
          redirect_to '/rsvp' and return
        end
      end

      response = rsvp.save

      rsvp = Parse::Query.new("RSVP").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      rsvp["user"] = user.pointer

      if rsvp["application"].blank?
        rsvp["application"] = @app.pointer
      end

      rsvp.save

      redirect_to '/rsvp'  and return
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      puts e.message
      redirect_to '/rsvp' and return
    end

  end

  def usercode
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign in."
      session[:return_to] = '/mycode'
      redirect_to '/login'
    elsif !@javascript_active
      session[:return_to] = '/mycode'
      redirect_to '/jscheck'
    else
      begin
        @rsvp = Parse::Query.new("RSVP").tap do |q|
                        q.eq("user", Parse::Pointer.new({
                          "className" => "_User",
                          "objectId"  => cookies.signed[:spartaUser][0]
                        }))
                end.get.first

        if @rsvp.blank? || @rsvp["attending"] == false
          redirect_to "/dashboard"
        else
          @user = cookies.signed[:spartaUser][0]
          render layout: false
        end
      rescue
        redirect_to "/outage" and return
      end
    end
  end

  def forgot
    render layout: false
  end

  def requestreset
    begin
      Parse::User.reset_password(forgot_password_params[:email])
      render layout: false
    rescue Parse::ParseProtocolError => e
      message = e.to_s.split(": ")[1]
      flash[:error] = message.slice(0,1).capitalize + message.slice(1..-1)
      redirect_to '/forgot'
    end
  end

  private

    def user_app_params
      params.permit(:email, :password, :password_confirmation, :firstName, :lastName, :gender, :birthday,
                                  :birthmonth, :birthyear, :university, :otherUniversityConfirm,
                                  :otherUniversity, {:major => []}, :gradeLevel,
                                  :whyAttend, {:hackathons => []}, :github, :linkedIn,
                                  :website, :devPost, :coolLink, :universityStudent, :mlh)
    end

    def user_rsvp_params
      params.permit(:attending, :university, {:restrictions => []}, :otherRestrictions, :tshirt, :resume)
    end

    def user_login_params
      params.permit(:email, :password)
    end

    def forgot_password_params
      params.permit(:email)
    end

		def register_params
      params.permit(:t)
    end

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end
end
