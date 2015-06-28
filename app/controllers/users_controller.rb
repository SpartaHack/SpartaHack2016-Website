class UsersController < ApplicationController
	require 'parse_config'
  def new
  	@user = User.new
  	@error = flash[:error]
  end

  #create a user and redirect them to application process
  def create
    if user_signup_params['password'] == user_signup_params['password_confirmation']
    	begin

				signup = Parse::User.new({
				  :username => user_signup_params['username'],
				  :email => user_signup_params['email'],
				  :password => user_signup_params['password'],
				})
				response = signup.save
				flash[:id] = response["objectId"]
				redirect_to '/app'	
			rescue Parse::ParseProtocolError => e
				if e.to_s.split(":").first == '202'
			  	flash[:error] = "Username is taken"
			  elsif e.to_s.split(":").first == "203"
			  	flash[:error] = "Email is taken"
			  end
			  redirect_to '/signup'
			end
			
    else
    	flash[:error] = "Passwords do not match"
      redirect_to '/signup'
    end
  end

  def login
  	@user = User.new
  	@error = flash[:error]
  end

  # authenticate user and redirect them to their application
  def auth
  	begin
			login = Parse::User.authenticate(user_login_params['username'],user_login_params['password'])
			redirect_to '/myapp'	
		rescue Parse::ParseProtocolError => e
			if e.to_s.split(":").first == '101'
		  	flash[:error] = "Username or password is incorrect"
		  	redirect_to '/login'
		  end
		end

  end  

  def app
  	user_id = flash[:id]
  	
  end

  private

    def user_signup_params
      params.require(:user).permit(:username, :email, :password,
                                   :password_confirmation)
    end

    def user_login_params
      params.require(:user).permit(:username, :password)
    end
end
