class UsersController < ApplicationController
	require 'parse_config'
  require 'monkey_patch'

  def new
    render layout: false
    cookies.delete :spartaUser
  	@error = flash[:error]
  end

  #create a user and redirect them to application process
  def create
    if user_apply_params['email'] == "" && user_apply_params['password'] == "" && user_apply_params['password_confirmation'] == ""
        flash[:error] = "You cannot submit an empty application."
        redirect_to '/apply' and return
    elsif user_apply_params['password'] != user_apply_params['password_confirmation']
    	flash[:error] = "Passwords do not match"
      redirect_to '/apply' and return
    else
      if user_apply_params['email'].downcase !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        flash[:error] = "You must use a valid email."
        redirect_to '/apply' and return
      end
      begin
        apply = Parse::User.new({
          :username => user_apply_params['email'],
          :email => user_apply_params['email'],
          :password => user_apply_params['password'],
          :role => "attendee"
        })
        response = apply.save
        cookies.permanent.signed[:spartaUser] = { value: [response["objectId"], "attendee"] }
      rescue Parse::ParseProtocolError => e
        if e.to_s.split(":").first == '202' || e.to_s.split(":").first == "203"
          flash[:error] = "Email is taken"
          redirect_to '/apply' and return
        end
        
      end
      redirect_to '/application' and return
    end
  end

  def login
    if cookies.signed[:spartaUser]
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("userId", Parse::Pointer.new({
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

      end      

    elsif !@javascript_active
      redirect_to '/noJS'
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
			login = Parse::User.authenticate(user_login_params['email'],user_login_params['password'])
      if login["role"] == "admin" || login["role"] == "sponsorship" || login["role"] == "statistics"
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], login["role"]] }
			  redirect_to '/admin' and return
      else
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], "attendee"] }
        begin
          @application = Parse::Query.new("Application").tap do |q|
            q.eq("userId", Parse::Pointer.new({
              "className" => "_User",
              "objectId"  => login["objectId"]
            }))
          end.get.first

          if @application
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

  def application
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign up to create an application."
      redirect_to '/apply'
    elsif !@javascript_active
      redirect_to '/noJS'
    else
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first

      if user["emailVerified"] == false
        redirect_to '/verify' and return
      end

      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("userId", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
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

  def dashboard

    @application = Parse::Query.new("Application").tap do |q|
      q.eq("userId", Parse::Pointer.new({
        "className" => "_User",
        "objectId"  => cookies.signed[:spartaUser][0]
      }))
    end.get.first

    @rsvp = Parse::Query.new("RSVP").tap do |q|
                    q.eq("userId", Parse::Pointer.new({
                      "className" => "_User",
                      "objectId"  => cookies.signed[:spartaUser][0]
                    }))
            end.get.first

    if !@application
      redirect_to '/application' and return
    end

    render layout: false
  end

  def rsvp
    @application = Parse::Query.new("Application").tap do |q|
      q.eq("userId", Parse::Pointer.new({
        "className" => "_User",
        "objectId"  => cookies.signed[:spartaUser][0]
      }))
    end.get.first

    if !@application
      redirect_to '/application' and return
    else
      if @application["status"] != "Accepted"
        redirect_to '/dashboard' and return
      end
    end

    @rsvp = Parse::Query.new("RSVP").tap do |q|
                    q.eq("userId", Parse::Pointer.new({
                      "className" => "_User",
                      "objectId"  => cookies.signed[:spartaUser][0]
                    }))
            end.get.first

    render layout: false
  end

  def saversvp
    begin
      fields = [ "university", "restrictions", "otherRestrictions", "tshirt", "citizen"]

      rsvp = Parse::Query.new("RSVP").tap do |q|
                      q.eq("userId", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
            end.get.first

      if !user_rsvp_params["attending"].blank? && user_rsvp_params["attending"] == "true"
        if user_rsvp_params["university"].blank? || user_rsvp_params["restrictions"].blank? || 
          user_rsvp_params["tshirt"].blank? || user_rsvp_params["citizen"].blank?

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
        rsvp['taxForm'] = nil
        rsvp.save

        rsvp = Parse::Query.new("RSVP").eq("objectId", response["objectId"]).get.first
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
        rsvp.array_add_relation("userId", user.pointer)
        rsvp.save

        redirect_to '/rsvp'  and return
      end

      if !rsvp
        if user_rsvp_params["resume"].blank? || user_rsvp_params["taxForm"].blank?
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
        if field == "citizen" && user_rsvp_params[field] == "true"
          rsvp[field] = true
        elsif field == "citizen" && user_rsvp_params[field] == "false"
          rsvp[field] = false
        else
          rsvp[field] = user_rsvp_params[field]
        end
      end
      rsvp['attending'] = true

      if !user_rsvp_params['resume'].blank?
        #save resume to parse
        resume = user_rsvp_params['resume'] 
        parse_resume = Parse::File.new({
          :body => resume.read,
          :local_filename => resume.original_filename.gsub(" ", "%20").gsub("[", "").gsub("]", ""),
          :content_type => resume.content_type,
          :content_length => resume.tempfile().size().to_s
        })
        parse_resume.save

        rsvp['resume'] = parse_resume
      end

      if !user_rsvp_params['taxForm'].blank?
        #save tax form to parse
        tax_form = user_rsvp_params['taxForm']
        parse_tax_form = Parse::File.new({
          :body => tax_form.read,
          :local_filename => tax_form.original_filename.gsub(" ", "%20").gsub("[", "").gsub("]", ""),
          :content_type => tax_form.content_type,
          :content_length => tax_form.tempfile().size().to_s
        })
        parse_tax_form.save

        rsvp['taxForm'] = parse_tax_form
      end

      response = rsvp.save

      rsvp = Parse::Query.new("RSVP").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      rsvp.array_add_relation("userId", user.pointer)
      rsvp.save

      redirect_to '/rsvp'  and return
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      puts e.message
      puts "sdfasdf------------------------------------------------------------------"
      redirect_to '/rsvp'
    end

  end  

  def verify
    user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
    @email = user["email"]
    render layout: false
  end

  def save

    if user_app_params["firstName"].blank? || user_app_params["lastName"].blank? || user_app_params["gender"].blank? || 
        user_app_params["birthday"].blank?|| user_app_params["birthmonth"].blank? || user_app_params["birthyear"].blank? || 
        user_app_params["universityStudent"].blank? || user_app_params["mlh"].blank?
      flash[:popup] = "You must fill in all the required fields."
      redirect_to '/application'  and return
    end

    begin
      fields = [ "firstName", "lastName", "gender", "birthday", "birthmonth", "birthyear", 
                                "major", "gradeLevel", "whyAttend", "hackathons", 
                                "github", "linkedIn", "website", "devPost", "coolLink", 
                                "universityStudent", "mlh"]

      application = Parse::Query.new("Application").tap do |q|
                      q.eq("userId", Parse::Pointer.new({
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
      application.array_add_relation("userId", user.pointer)
      application.save

      redirect_to '/application'  and return
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      redirect_to '/apply'
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

    def user_apply_params
      params.permit(:email, :password, :password_confirmation)
    end

    def user_app_params
      params.permit(:firstName, :lastName, :gender, :birthday, :birthmonth, :birthyear, 
                                  :university, :otherUniversityConfirm,:otherUniversity, {:major => []}, :gradeLevel, 
                                  :whyAttend, {:hackathons => []}, :github, :linkedIn, 
                                  :website, :devPost, :coolLink, :universityStudent, :mlh)     
    end

    def user_rsvp_params
      params.permit(:attending, :university, {:restrictions => []}, :otherRestrictions, :tshirt, :resume, 
                                :citizen, :taxForm)     
    end

    def user_login_params
      params.permit(:email, :password)
    end

    def forgot_password_params
      params.permit(:email)
    end
end
