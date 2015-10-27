class UsersController < ApplicationController
	require 'parse_config'
  require 'monkey_patch'

  def new
    render layout: false
    cookies.delete :spartaUser
  	@user = User.new
  	@error = flash[:error]
  end

  #create a user and redirect them to application process
  def create
    if user_apply_params['password'] == user_apply_params['password_confirmation']
    	begin
				apply = Parse::User.new({
				  :username => user_apply_params['email'],
				  :email => user_apply_params['email'],
				  :password => user_apply_params['password'],
          :role => "attendee"
				})
				response = apply.save
				cookies.signed[:spartaUser] = { value: response["objectId"], expires: (Time.now.getgm + 86400) }
				redirect_to '/app'	
			rescue Parse::ParseProtocolError => e
        puts e.to_s
				if e.to_s.split(":").first == '202'
			  	flash[:error] = "Email is taken"
			  elsif e.to_s.split(":").first == "203"
			  	flash[:error] = "Email is taken"
			  end
			  redirect_to '/apply'
			end
			
    else
    	flash[:error] = "Passwords do not match"
      redirect_to '/apply'
    end
  end

  def login
    if cookies.signed[:spartaUser]
      redirect_to '/app' and return
    else
      render layout: false
    end
  end

  # authenticate user and redirect them to their application
  def auth
  	begin
			login = Parse::User.authenticate(user_login_params['email'],user_login_params['password'])
      cookies.signed[:spartaUser] = { value: login["objectId"], expires: (Time.now.getgm + 86400) }
      if login["role"] == "admin"
			  redirect_to '/admin'
      else
        redirect_to '/app'
      end
		rescue Parse::ParseProtocolError => e
			if e.to_s.split(":").first == '101'
		  	flash[:error] = "Password is incorrect"
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
            "objectId"  => cookies.signed[:spartaUser]
          }))
        end.get.first
        print @application["major"]
        print "\n"
        @application["major"] = @application["major"].to_a
        print @application["major"]
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
                                "university", "otherUniversity", "major", "gradeLevel", 
                                "whyAttend", "hackathons", "github", "linkedIn", 
                                "website", "devPost", "coolLink",]
      print user_app_params["hackathons"]

      application = Parse::Query.new("Application").tap do |q|
                      q.eq("userId", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser]
                      }))
                    end.get.first
      if !application
        application = Parse::Object.new("Application")
      end
      fields.each do |field|
        application[field] = user_app_params[field]
      end
      response = application.save

      application = Parse::Query.new("Application").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser]).get.first
      application.array_add_relation("userId", user.pointer)
      application.save

      redirect_to '/app'  
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      redirect_to '/apply'
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
                                  :website, :devPost, :coolLink)     
    end

    def user_login_params
      params.permit(:email, :password)
    end
end
