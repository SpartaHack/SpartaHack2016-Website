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
        print e
        if e.to_s.split(":").first == '202' || e.to_s.split(":").first == "203"
          flash[:error] = "Email is taken"
          redirect_to '/apply' and return
        end
        
      end
      redirect_to '/app' and return
    end
  end

  def login
    if cookies.signed[:spartaUser]
      redirect_to '/app' and return
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
      if login["role"] == "admin"
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], "admin"] }
			  redirect_to '/admin' and return
      else
        cookies.permanent.signed[:spartaUser] = { value: [login["objectId"], "attendee"] }
        redirect_to '/app' and return
      end
		rescue Parse::ParseProtocolError => e
			if e.to_s.split(":").first == '101'
		  	flash[:error] = "Invalid credentials."
		  	redirect_to '/login'
		  end
		end

  end  

  def app
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign up to create an application."
      redirect_to '/apply'
    else
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("userId", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser][0]
          }))
        end.get.first

        if @application
          if @application["university"]
            @application["universitystudent"] = true
          else 
            @application["universitystudent"] = false
          end
        end

        render layout: false
      rescue Parse::ParseProtocolError => e
        flash[:error] = e.message
        redirect_to '/login'
      end
    end
  end


  def save
    begin
      fields = [ "firstName", "lastName", "gender", "birthday", "birthmonth", "birthyear", 
                                "major", "gradeLevel", "whyAttend", "hackathons", 
                                "github", "linkedIn", "website", "devPost", "coolLink", 
                                "universitystudent"]

      application = Parse::Query.new("Application").tap do |q|
                      q.eq("userId", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser][0]
                      }))
                    end.get.first
      if !application
        application = Parse::Object.new("Application")
      end

      fields.each do |field|
        if field == "universitystudent" && user_app_params[field].to_bool == true
          application["university"] = user_app_params["university"]
          application["otherUniversity"] = user_app_params["otherUniversity"]
        else
          application["university"] = nil
          application["otherUniversity"] = nil
        end
        application[field] = user_app_params[field]
      end
      response = application.save

      application = Parse::Query.new("Application").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      application.array_add_relation("userId", user.pointer)
      application.save

      flash[:popup] = "Application saved successfully."
      redirect_to '/app'  and return
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
                                  :university, :otherUniversity, {:major => []}, :gradeLevel, 
                                  :whyAttend, {:hackathons => []}, :github, :linkedIn, 
                                  :website, :devPost, :coolLink, :universitystudent)     
    end

    def user_login_params
      params.permit(:email, :password)
    end

    def forgot_password_params
      params.permit(:email)
    end
end
