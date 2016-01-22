class UserMailer < ApplicationMailer

	def notify_of_status(name, user)
		@name = name
		mail :to => user, :from => "hello@spartahack.com", :subject => "SpartaHack 2016 Decision"
	end

	def notify_of_empty_app(user)
		mail :to => user, :from => "hello@spartahack.com", :subject => "Complete your SpartaHack application"
	end

end
