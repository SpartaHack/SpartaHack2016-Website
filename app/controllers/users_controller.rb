class UsersController < ApplicationController
	require 'parse_config'
  require 'monkey_patch'

  def new
    if !@javascript_active
      redirect_to '/noJS'
    else
      render layout: false
      cookies.delete :spartaUser
    	@error = flash[:error]
    end
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
      print login
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
    print 
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign up to create an application."
      redirect_to '/apply'
    elsif !@javascript_active
      redirect_to '/noJS'
    else
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      print user
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
          print @application["universitystudent"]
          print "------------------------"
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

  def verify
    user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
    @email = user["email"]
    print @email
    render layout: false
  end

  def save

    if user_app_params["firstName"].blank? || user_app_params["lastName"].blank? || user_app_params["gender"].blank? || 
        user_app_params["birthday"].blank?|| user_app_params["birthmonth"].blank? || user_app_params["birthyear"].blank? || 
        user_app_params["universitystudent"].blank? || user_app_params["mlh"].blank?
      flash[:popup] = "You must fill in all the required fields."
      redirect_to '/app'  and return
    end

    begin
      fields = [ "firstName", "lastName", "gender", "birthday", "birthmonth", "birthyear", 
                                "major", "gradeLevel", "whyAttend", "hackathons", 
                                "github", "linkedIn", "website", "devPost", "coolLink", 
                                "universitystudent", "mlh"]

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
        if field == "universitystudent" && user_app_params["universitystudent"].to_bool == true
          application["universitystudent"] = "true"
          application["university"] = user_app_params["university"]
          application["otherUniversity"] = user_app_params["otherUniversity"]
        elsif field == "universitystudent" && user_app_params["universitystudent"].to_bool == false
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
                                  :website, :devPost, :coolLink, :universitystudent, :mlh)     
    end

    def user_login_params
      params.permit(:email, :password)
    end

    def forgot_password_params
      params.permit(:email)
    end
end
